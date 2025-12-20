#include "cpu.hpp"
#include "cache.hpp"
#include <iostream>
#include <stdexcept>

CPU::CPU(std::vector<Instruction> program)
    : program_(std::move(program)),
      memory_(1 << 20, 0), // 1M words
      cycle_(0),
      instr_count_(0),
      total_cycles_(0),
      cache_(memory_.data()),
      mem_pending_(false),
      mem_wait_(0),
      mem_instr_({}),
      mem_load_val_(0)
{}

void CPU::run(int max_steps) {
    printf("loading run\n");
    int steps = 0;
    running_ = true;

    while (running_) {
        if (steps++ >= max_steps) {
            throw std::runtime_error("Max steps exceeded (possible infinite loop)");
        }
        step();
    }

    printf("Instructions: %lu\n", instr_count_);
    printf("Cycles: %lu\n", total_cycles_);
    printf("CPI: %.2f\n", (double)total_cycles_ / instr_count_);
}

void CPU::step() {

    printf("\n=== Cycle %lu ===\n", cycle_);

    print_instr("IF",  if_id_.instr);
    print_instr("ID",  id_ex_.instr);
    print_instr("EX", id_ex_.instr.valid ? id_ex_.instr : Instruction{});
    print_instr("MEM", ex_mem_.valid ? ex_mem_.instr : Instruction{});
    print_instr("WB", mem_wb_.valid ? mem_wb_.instr : Instruction{});

    // write back stage
    if (mem_wb_.valid && mem_wb_.reg_write) {
        regs_[mem_wb_.rd] = mem_wb_.writeback_value;
        printf("WB | r%d = %d\n", mem_wb_.rd, mem_wb_.writeback_value);
    }

    mem_wb_.valid = false;
    EX_MEM  ex_mem_next{};
    MEM_WB  mem_wb_next{};
    ex_mem_next.valid = false;
    mem_wb_next.valid = false;

    // handle memory operations
    if (mem_pending_) {
        printf("MEMWAIT | remaining=%d\n", mem_wait_);
        if (mem_wait_ > 0) {
            mem_wait_--;
        }
        if (mem_wait_ == 0) {
            printf("MEMDONE | completing %s\n", opcode_to_str(mem_instr_.op));

            if (mem_instr_.op == Opcode::LOAD) {
                mem_wb_.valid = true;
                mem_wb_.rd = mem_instr_.rd;
                mem_wb_.writeback_value = mem_load_val_;
                mem_wb_.reg_write = true;

                printf("MEMDONE | load ready for WB r%d = %d\n",
                    mem_instr_.rd, (int)mem_load_val_);
            }
            instr_count_++;
            mem_pending_ = false;
        }
        enforce_x0();
        cycle_++;
        total_cycles_++;
        return;
    }

    // handle branch
    if (branch_taken_) {
        printf("FLUSH | branch taken → PC=%d\n", branch_target_);
        pc_ = branch_target_;
        if_id_.valid = false;
        id_ex_.valid = false;
        branch_taken_ = false;

        flush_count_++;
    }

    // hazard detection for loads
    bool stall = false;

    if (if_id_.valid && id_ex_.valid && id_ex_.instr.op == Opcode::LOAD) {
        const Instruction& younger = if_id_.instr;
        if (has_dependency(younger.rs1, id_ex_.instr) || has_dependency(younger.rs2, id_ex_.instr)) {
            stall = true;
            printf("STALL | load-use on r%d\n", id_ex_.instr.rd);
            stall_count_++;
        }
    }

    // execute
    if (id_ex_.valid) {
        Opcode op = id_ex_.instr.op;
        execute(ex_mem_next, mem_wb_next);
        if (!(mem_pending_ && (op == Opcode::LOAD || op == Opcode::STORE))) {
            instr_count_++;
        }
        id_ex_.valid = false;   // instruction leaves pipeline
    }

    // decode
    if (!stall && if_id_.valid && !id_ex_.valid) {
        const Instruction& in = if_id_.instr;

        id_ex_.instr = in;
        id_ex_.rs1_val = regs_[in.rs1];
        id_ex_.rs2_val = regs_[in.rs2];
        id_ex_.store_val = regs_[in.rd];
        id_ex_.valid = true;
        if_id_.valid = false;
    }

    // fetch
    if (!stall && !if_id_.valid) {
        if_id_.instr = fetch();
        if_id_.valid = if_id_.instr.valid;
    }

    // mem: move EX result to WB
    if (ex_mem_next.valid && ex_mem_next.reg_write) {
        mem_wb_next.valid = true;
        mem_wb_next.rd = ex_mem_next.rd;
        mem_wb_next.writeback_value = ex_mem_next.alu_result;
        mem_wb_next.reg_write = true;
        mem_wb_next.instr = ex_mem_.instr;
    }

    ex_mem_ = ex_mem_next;
    mem_wb_ = mem_wb_next;

    cycle_++;           // <-- THIS DEFINES A CLOCK EDGE
    total_cycles_++; 
    enforce_x0();
}


Instruction CPU::fetch() {

    // handle halt + out of bounds
    if (pc_ < 0 || pc_ >= (int)program_.size()) {
        Instruction halt{};
        halt.op = Opcode::HALT; 
        halt.valid = true;
        halt.pc = pc_;
        return halt;
    }

    Instruction instr = program_[pc_];
    instr.valid = true;
    instr.pc = pc_;
    pc_++;
    return instr;
}

void CPU::execute(EX_MEM& ex_mem_next, MEM_WB& mem_wb_next) {

    const Instruction& instr = id_ex_.instr;

    int32_t srcA = id_ex_.rs1_val;
    int32_t srcB = id_ex_.rs2_val;

    // EX → EX forwarding (newest)
    if (ex_mem_.valid && ex_mem_.reg_write && ex_mem_.rd != 0) {
        printf("EX forwarding | r%d -> %d\n", ex_mem_.rd, ex_mem_.alu_result);
        if (ex_mem_.rd == instr.rs1) srcA = ex_mem_.alu_result;
        if (ex_mem_.rd == instr.rs2) srcB = ex_mem_.alu_result;
        if (ex_mem_.rd == instr.rd) id_ex_.store_val = ex_mem_.alu_result;
    }

    printf("EX | srcA=%d srcB=%d\n", srcA, srcB);
    switch (instr.op) {
        case Opcode::ADD: {
            int32_t alu_out = srcA + srcB;
            ex_mem_next.valid = true;
            ex_mem_next.rd = instr.rd;
            ex_mem_next.alu_result = alu_out;
            ex_mem_next.reg_write = true;
            ex_mem_next.instr = instr;
            break;
        }
        case Opcode::SUB: {
            int32_t alu_out = srcA - srcB;
            ex_mem_next.valid = true;
            ex_mem_next.rd = instr.rd;
            ex_mem_next.alu_result = alu_out;
            ex_mem_next.reg_write = true;
            ex_mem_next.instr = instr;

            break;
        }
        case Opcode::ADDI: {
            int32_t alu_out = srcA + instr.imm;
            ex_mem_next.valid = true;
            ex_mem_next.rd = instr.rd;
            ex_mem_next.alu_result = alu_out;
            ex_mem_next.reg_write = true;
            ex_mem_next.instr = instr;

            break;
        }

        case Opcode::LOAD: {
            // Define your addressing convention.
            // Here: effective address = regs[rs1] + imm, measured in WORD indices.
            uint32_t addr = (uint32_t)(srcA + instr.imm);
            int32_t val;
            int latency = cache_.load(addr, val);

            printf("LOAD latency: %d cycles\n", latency);
            if (latency == 1) {
                mem_wb_next.valid = true;
                mem_wb_next.rd = instr.rd;
                mem_wb_next.writeback_value = val;
                mem_wb_next.reg_write = true;
                mem_wb_next.instr = ex_mem_.instr;
            } else {
                // Start a pending memory operation
                mem_pending_   = true;
                mem_wait_      = latency - 1;   // minus 1
                mem_instr_     = instr;
                mem_load_val_  = val;
            }
            break;
        }
        case Opcode::STORE: {
            uint32_t addr = (uint32_t)(srcA + instr.imm);
            int32_t val = id_ex_.store_val;

            int latency = cache_.store(addr, val);
            printf("STORE latency: %d cycles\n", latency);
            if (latency > 1) {
                mem_pending_ = true;
                mem_wait_    = latency - 1;
                mem_instr_   = instr;
            }
            break;
        }

        case Opcode::BEQ: {
            if (srcA == srcB) {
                branch_taken_ = true;
                branch_target_ = instr.pc + instr.imm;
            }
            break;
        }

        case Opcode::JAL: {
            regs_[instr.rd] = instr.pc; // pc already incremented in fetch
            branch_taken_ = true;
            branch_target_ = instr.pc + instr.imm;
            break;
        }

        case Opcode::HALT: {
            running_ = false;
            break;
        }
        case Opcode::NOP:
        default:
            // treat unknown as NOP or throw
            break;
    }
}

bool CPU::writes_rd(const Instruction& instr) {
    switch (instr.op) {
        case Opcode::ADD:
        case Opcode::SUB:
        case Opcode::ADDI:
        case Opcode::LOAD:
        case Opcode::JAL:
            return true;
        default:
            return false;
    }
}

bool CPU::has_dependency(uint8_t r, const Instruction& older) {
    if (r == 0) return false;              // x0 safe
    if (!older.valid) return false;
    if (!writes_rd(older)) return false;
    return older.rd == r; // does old load affect current function?
}

int32_t CPU::mem_word(uint32_t addr) const {
    if (addr >= memory_.size()) throw std::out_of_range("mem_word: OOB");
    return memory_[addr];
}

const char* CPU::opcode_to_str(Opcode op) {
    switch (op) {
        case Opcode::ADD: return "ADD";
        case Opcode::ADDI: return "ADDI";
        case Opcode::SUB: return "SUB";
        case Opcode::LOAD: return "LD";
        case Opcode::STORE: return "ST";
        case Opcode::BEQ: return "BEQ";
        case Opcode::NOP: return "NOP";
        case Opcode::HALT: return "HALT";
        default: return "UNK";
    }
}

void CPU::print_instr(const char* stage, const Instruction& instr) {
    if (!instr.valid) {
        printf("  %-5s | ----\n", stage);
        return;
    }

    printf(
        "  %-5s | PC=%3d OP=%-3s r%d r%d r%d\n",
        stage,
        instr.pc,
        opcode_to_str(instr.op),
        instr.rd,
        instr.rs1,
        instr.rs2
    );
}

void CPU::enforce_x0() {
    regs_[0] = 0;
}
