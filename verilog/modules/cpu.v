`include "modules/instruction_fetch.v"
`include "modules/isa_decoder.v"
`include "modules/register_file.v"
`include "modules/data_memory.v"
`include "modules/execute.v"

module cpu (
    input wire clk,
    input wire reset
);

    // ======== Internal Wires ========
    wire [31:0] instruction;
    wire [31:0] pc_value;

    // Outputs from execute
    wire [3:0] opcode, rs1, rs2, rd;
    wire [15:0] imm;
    wire [31:0] rs1_val, rs2_val;
    wire [31:0] rd_value;
    wire [31:0] mem_data_out;
    wire [31:0] mem_data_in;
    wire [31:0] mem_addr;

    wire reg_write_en;
    wire mem_read_en, mem_write_en;
    wire branch_taken;
    wire [15:0] branch_target;
    wire halt;

    // PC logic for fetch
    wire pc_load_en = branch_taken;
    wire [31:0] pc_next = branch_taken ? {32'd0, branch_target} : (pc_value + 1);
    
    // ======== FETCH ========
    instruction_fetch fetch (
        .clk(clk),
        .reset(reset),
        .load_en(pc_load_en),
        .pc_next(pc_next),
        .current_instruction(instruction),
        .current_pc(pc_value)
    );

    // ======== DECODE ========
    isa_decoder decoder (
        .instruction(instruction),
        .opcode(opcode),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .imm(imm)
    );

    // ======== REGISTER FILE ========
    register_file regfile (
        .clk(clk),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(rd_value),
        .reg_write(reg_write_en),
        .rs1_data(rs1_val),
        .rs2_data(rs2_val)
    );

    // ======== DATA MEMORY ========
    data_memory dmem (
        .clk(clk),
        .mem_read(mem_read_en),
        .mem_write(mem_write_en),
        .address(mem_addr),
        .write_data(mem_data_out),
        .read_data(mem_data_in)
    );

    // ======== EXECUTE ========
    execute exec (
        .opcode(opcode),
        .rs1_val(rs1_val),
        .rs2_val(rs2_val),
        .rd(rd),
        .imm(imm),
        .pc(pc_value[15:0]),
        .mem_data_in(mem_data_in),

        .rd_value(rd_value),
        .reg_write_en(reg_write_en),

        .mem_read_en(mem_read_en),
        .mem_write_en(mem_write_en),
        .mem_addr(mem_addr),
        .mem_data_out(mem_data_out),

        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .halt(halt)
    );

    // ======== HALT ========
    always @(posedge clk) begin
        $display("============== CYCLE @ %0t ns ==============", $time);
        $display("PC = %0d", pc_next);
        $display("Instruction = %b", instruction);
        $display("Opcode = %b | rs1 = %0d | rs2 = %0d | rd = %0d | imm = %0d", opcode, rs1, rs2, rd, imm);
        $display("rs1_val = %0d | rs2_val = %0d", rs1_val, rs2_val);
        $display("rd_value = %0d", rd_value);
        $display("Memory Read Enable = %b | Memory Write Enable = %b", mem_read_en, mem_write_en);
        $display("Memory Addr = %0d | Data Out = %0d | Data In = %0d", mem_addr, mem_data_out, mem_data_in);
        $display("Branch Taken = %b | Branch Target = %0d", branch_taken, branch_target);
        $display("Reg Write Enable = %b", reg_write_en);
        $display("--------------------------------------------");

        if (halt) begin
            $display("HALT instruction encountered at PC=%0d. Halting simulation.", pc_value);
            regfile.display_all();
            $finish;
        end
    end

endmodule
