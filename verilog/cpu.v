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
    // Pipelining
    
    // from fetch
    wire [31:0] if_instr_w;
    wire [31:0] if_pc_w;
    reg [31:0] if_id_instr;
    reg [31:0] if_id_pc;

    // from decode
    wire [3:0]  id_ex_opcode_w;
    wire [3:0]  id_ex_rd_w;
    wire [3:0]  id_ex_rs1_w;
    wire [3:0]  id_ex_rs2_w;
    wire [15:0] id_ex_imm_w;
    wire [31:0] id_ex_rs1_val_w;
    wire [31:0] id_ex_rs2_val_w;
    
    reg [3:0]  id_ex_opcode;
    reg [3:0]  id_ex_rd;
    reg [3:0]  id_ex_rs1;
    reg [3:0]  id_ex_rs2;
    reg [15:0] id_ex_imm;
    reg [31:0] id_ex_rs1_val;
    reg [31:0] id_ex_rs2_val;
    reg [31:0] id_ex_pc;
    
    // from execute
    wire ex_mem_read_en_w;
    wire ex_mem_write_en_w;
    wire [31:0] ex_mem_addr_w;
    wire [31:0] ex_mem_data_out_w;

    wire ex_mem_branch_taken_w;
    wire [15:0] ex_mem_branch_target_w;
    wire ex_mem_halt_w;
    

    reg [3:0] ex_mem_rs2;
    reg [31:0] ex_mem_rs2_val;
    reg [31:0] ex_mem_pc;

    reg ex_mem_read_en;
    reg ex_mem_write_en;
    reg [31:0] ex_mem_addr;
    reg [31:0] ex_mem_data_out;

    reg ex_mem_branch_taken;
    reg [15:0] ex_mem_branch_target;
    reg ex_mem_halt;
    reg ex_mem_halt_final;

    // Mem registor store
    wire [31:0] ex_mem_rd_value_w;
    wire ex_mem_reg_write_en_w;

    reg [3:0] ex_mem_rd;
    reg [31:0] ex_mem_rd_value;
    reg ex_mem_reg_write_en;

    // MEM phase
    
    reg [3:0] mem_wb_rd;
    reg [31:0] mem_wb_rd_value;
    reg mem_wb_reg_write_en; 

    // stalling?
    wire load_in_ex = (id_ex_opcode == 4'b0011); // LOAD opcode
    wire load_use_hazard =
    load_in_ex &&
    (id_ex_rd != 4'd0) &&
    ((id_ex_rd == id_ex_rs1_w) || (id_ex_rd == id_ex_rs2_w));

    // store forward
    wire [31:0] store_data_fixed =
        (ex_mem_write_en && mem_wb_reg_write_en && (mem_wb_rd != 0) && (mem_wb_rd == ex_mem_rs2))
        ? mem_wb_rd_value
        : ex_mem_rs2_val;

    // PC logic for fetch
    wire pc_load_en = ex_mem_branch_taken;
    wire [31:0] pc_next = {16'd0, ex_mem_branch_target};
    
    // ======== FETCH ========
    instruction_fetch fetch (
        .clk(clk),
        .reset(reset),
        .load_en(pc_load_en),
        .en(!load_use_hazard),
        .pc_next(pc_next),
        .current_instruction(if_instr_w),
        .current_pc(if_pc_w)
    );

    always @(posedge clk) begin
        if (reset) begin
            // for exe now
            if_id_instr <= 32'b0;
            if_id_pc    <= 32'b0;
        end else if (!load_use_hazard) begin
            if_id_instr <= if_instr_w;
            if_id_pc    <= if_pc_w;
        end
    end

    // ======== DECODE ========
    isa_decoder decoder (
        .instruction(if_id_instr),
        .opcode(id_ex_opcode_w),
        .rs1(id_ex_rs1_w),
        .rs2(id_ex_rs2_w),
        .rd(id_ex_rd_w),
        .imm(id_ex_imm_w)
    );

    // ======== REGISTER FILE ========
    register_file regfile (
        .clk(clk),
        .rs1(id_ex_rs1_w),
        .rs2(id_ex_rs2_w),
        .rd(mem_wb_rd),
        .write_data(mem_wb_rd_value),
        .reg_write(mem_wb_reg_write_en),
        .rs1_data(id_ex_rs1_val_w),
        .rs2_data(id_ex_rs2_val_w)
    );

    wire [31:0] id_rs1_val_byp =
        (mem_wb_reg_write_en && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs1_w))
            ? mem_wb_rd_value
            : id_ex_rs1_val_w;

    wire [31:0] id_rs2_val_byp =
        (mem_wb_reg_write_en && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs2_w))
            ? mem_wb_rd_value
            : id_ex_rs2_val_w;
            
    localparam [3:0] OP_NOP = 4'b1111;

    always @(posedge clk) begin
        if (reset) begin
            id_ex_opcode   <= 4'b0;
            id_ex_rs1      <= 4'b0;
            id_ex_rs2      <= 4'b0;
            id_ex_rd       <= 4'b0;
            id_ex_imm      <= 16'b0;
            id_ex_rs1_val  <= 32'b0;
            id_ex_rs2_val  <= 32'b0;
            id_ex_pc       <= 32'b0;
            
        end else if (load_use_hazard) begin
            id_ex_opcode   <= OP_NOP; // bubble
            id_ex_rs1      <= 4'b0;
            id_ex_rs2      <= 4'b0;
            id_ex_rd       <= 4'b0;
            id_ex_imm      <= 16'b0;
            id_ex_rs1_val  <= 32'b0;
            id_ex_rs2_val  <= 32'b0;
            id_ex_pc       <= 32'b0;
        end else begin
            id_ex_opcode   <= id_ex_opcode_w;
            id_ex_rs1      <= id_ex_rs1_w;
            id_ex_rs2      <= id_ex_rs2_w;
            id_ex_rd       <= id_ex_rd_w;
            id_ex_imm      <= id_ex_imm_w;
            id_ex_rs1_val  <= id_rs1_val_byp;
            id_ex_rs2_val  <= id_rs2_val_byp;
            id_ex_pc       <= if_id_pc;          // or id_ex_pc_w if you want a wire
        end
    end
 
    // ======== EX FORWARDING (fixes add-after-load after the 1-cycle stall) ========
    wire exmem_writes = ex_mem_reg_write_en && (ex_mem_rd != 0);
    wire exmem_is_load = ex_mem_read_en;

    wire memwb_writes = mem_wb_reg_write_en && (mem_wb_rd != 0);

    // Forward for rs1
    wire fwd_a_exmem = exmem_writes && !exmem_is_load && (ex_mem_rd == id_ex_rs1);
    wire fwd_a_memwb = memwb_writes && (mem_wb_rd == id_ex_rs1) && !fwd_a_exmem;

    // Forward for rs2
    wire fwd_b_exmem = exmem_writes && !exmem_is_load && (ex_mem_rd == id_ex_rs2);
    wire fwd_b_memwb = memwb_writes && (mem_wb_rd == id_ex_rs2) && !fwd_b_exmem;

    wire [31:0] ex_rs1_val =
        fwd_a_exmem ? ex_mem_rd_value :
        fwd_a_memwb ? mem_wb_rd_value :
        id_ex_rs1_val;

    wire [31:0] ex_rs2_val =
        fwd_b_exmem ? ex_mem_rd_value :
        fwd_b_memwb ? mem_wb_rd_value :
        id_ex_rs2_val;

    // ======== EXECUTE ========
    execute exec (
        .opcode(id_ex_opcode),
        .rs1_val(ex_rs1_val),
        .rs2_val(ex_rs2_val),
        .rd(id_ex_rd),
        .imm(id_ex_imm),
        .pc(id_ex_pc[15:0]),
        .mem_data_in(mem_data_in),

        .rd_value(ex_mem_rd_value_w),
        .reg_write_en(ex_mem_reg_write_en_w),

        .mem_read_en(ex_mem_read_en_w),
        .mem_write_en(ex_mem_write_en_w),
        .mem_addr(ex_mem_addr_w),
        .mem_data_out(ex_mem_data_out_w),

        .branch_taken(ex_mem_branch_taken_w),
        .branch_target(ex_mem_branch_target_w),
        .halt(ex_mem_halt_w)
    );
    
    always @(posedge clk) begin
        if (reset) begin
            ex_mem_pc <= 32'd0;
            ex_mem_rd_value <= 32'd0;
            ex_mem_rd <= 4'd0;
            ex_mem_reg_write_en <= 1'd0;

            ex_mem_rs2 <= 4'd0;
            ex_mem_rs2_val <= 32'd0;
            ex_mem_read_en <= 1'd0;
            ex_mem_write_en <= 1'd0;
            ex_mem_addr <= 32'd0;
            ex_mem_data_out <= 32'd0;

            ex_mem_branch_taken <= 1'd0;
            ex_mem_branch_target <= 16'd0;
            ex_mem_halt <= 1'd0;
            ex_mem_halt_final <= 1'd0;
        end else begin
            ex_mem_pc <= id_ex_pc;
            ex_mem_rd_value <= ex_mem_rd_value_w;
            ex_mem_rd <= id_ex_rd;
            ex_mem_reg_write_en <= ex_mem_reg_write_en_w;

            ex_mem_rs2 <= id_ex_rs2;
            ex_mem_rs2_val <= ex_mem_write_en_w ? ex_mem_data_out_w : id_ex_rs2_val;
            ex_mem_read_en <= ex_mem_read_en_w;
            ex_mem_write_en <= ex_mem_write_en_w;
            ex_mem_addr <= ex_mem_addr_w;
            ex_mem_data_out <= ex_mem_data_out_w;

            ex_mem_branch_taken <= ex_mem_branch_taken_w;
            ex_mem_branch_target <= ex_mem_branch_target_w;
            ex_mem_halt <= ex_mem_halt_w;
        end
    end

    // ======== DATA MEMORY ========
    data_memory dmem (
        .clk(clk),
        .mem_read(ex_mem_read_en),
        .mem_write(ex_mem_write_en),
        .address(ex_mem_addr),
        .write_data(store_data_fixed),
        .read_data(mem_data_in)
    );

    always @(posedge clk) begin
        if (reset) begin
            mem_wb_rd <= 4'd0;
            mem_wb_rd_value <= 32'd0;
            mem_wb_reg_write_en <= 1'd0;
        end else begin
            if (ex_mem_read_en) begin
                mem_wb_rd_value <= mem_data_in;
            end else begin
                mem_wb_rd_value <= ex_mem_rd_value;
            end
            mem_wb_rd <= ex_mem_rd;
            mem_wb_reg_write_en <= ex_mem_reg_write_en;
        end
    end
    
    // if load store to register somehow

    
    always @(posedge clk) begin
        $display("============== CYCLE @ %0t ns ==============", $time);
        $display("Fetch Phase: pc: %0d, instr: %0d", if_id_pc, if_id_instr);
        $display("Decode Phase: pc: %0d, op: %0d, rd: %0d, rs1: %0d, rs2: %0d, imm: %0d, rs1_val: %0d, rs2_val: %0d",id_ex_pc, id_ex_opcode, id_ex_rd, id_ex_rs1, id_ex_rs2, id_ex_imm, id_ex_rs1_val, id_ex_rs2_val);
        $display("Execute Phase: pc: %0d, rd: %0d, rd val: %0d, mem_addr: %0d, branch_taken: %0d, branch_targ: %0d, data_out: %0d, halt: %0d", ex_mem_pc, ex_mem_rd, ex_mem_rd_value, ex_mem_addr, ex_mem_branch_taken, ex_mem_branch_target, ex_mem_data_out, ex_mem_halt);
        $display("Execute Phase: reg write: %0d, read enable: %0d, write enable: %0d, rs2 val: %0d", ex_mem_reg_write_en, ex_mem_read_en, ex_mem_write_en, ex_mem_rs2_val);
        $display("Memory phase: rd val: %0d, rd: %0d, write en: %0d", mem_wb_rd_value, mem_wb_rd, mem_wb_reg_write_en);
        $display("store data: %0d", store_data_fixed);
        if (ex_mem_halt) begin
            ex_mem_halt_final <= ex_mem_halt;
        end
        else if (ex_mem_halt_final) begin
            $display("HALT instruction encountered at PC=%0d. Halting simulation.", pc_value);
            regfile.display_all();
            $finish;
        end
    end

endmodule
