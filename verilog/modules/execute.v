module execute (
    input  wire [3:0]  opcode,
    input  wire [31:0] rs1_val,
    input  wire [31:0] rs2_val,
    input  wire [3:0]  rd,
    input  wire [15:0] imm,
    input  wire [31:0] mem_data_in,
    input  wire [15:0] pc,

    output reg  [31:0] rd_value,
    output reg         reg_write_en,

    output reg         mem_read_en,
    output reg         mem_write_en,
    output reg  [31:0] mem_addr,
    output reg  [31:0] mem_data_out,

    output reg         branch_taken,
    output reg  [15:0] branch_target,

    output reg         halt

);
    always @(*) begin
        rd_value      = 32'd0;
        reg_write_en  = 1'b0;

        mem_read_en   = 1'b0;
        mem_write_en  = 1'b0;
        mem_addr      = 32'd0;
        mem_data_out  = 32'd0;

        branch_taken  = 1'b0;
        branch_target = 16'd0;

        halt          = 1'b0;

        case (opcode)
            4'b0000: begin
                rd_value = rs1_val + rs2_val;   // ADD
                reg_write_en = 1;
            end
            4'b0001: begin
                rd_value = rs1_val - rs2_val;   // SUB
                reg_write_en = 1;
            end
            4'b0010: begin
                rd_value = rs1_val + imm;       // ADDI
                reg_write_en = 1;
            end
            4'b0011: begin                            // LOAD
                mem_addr     = rs1_val + imm;
                mem_read_en  = 1;
                rd_value     = mem_data_in;
                reg_write_en = 1;

            end
            4'b0100: begin                            // STORE
                mem_addr     = rs1_val + imm;
                mem_write_en = 1;
                mem_data_out = rs2_val;
            end
            4'b0101: if (rs1_val == rs2_val) begin // BEQ
                branch_taken  = 1;
                branch_target = pc + imm;

            end 
            4'b0111: begin // JAL
                rd_value = pc;  // 
                reg_write_en = 1;
                branch_taken = 1;
                branch_target = pc + imm;
            end
            4'b0110: begin
                halt = 1;  // HALT
            end
            4'b1111: begin
            // NOP: do nothing (defaults already zeroed)
            end
        endcase

    end
endmodule