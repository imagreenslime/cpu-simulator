`include "./modules/isa_decoder.v"
`timescale 1ns/1ps

module test_isa_decoder;

    reg clk;
    reg [31:0] instruction;
    wire [3:0] opcode, rd;
    wire [15:0] imm;
    wire [31:0] rs1_value, rs2_value;


    // Instantiate the actual register file separately to write into it
    reg [3:0] rs1, rs2, rd_write;
    reg [31:0] write_data;
    reg reg_write;
    wire [31:0] dummy1, dummy2;

    register_file rf (
        .clk(clk),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd_write),
        .write_data(write_data),
        .reg_write(reg_write),
        .rs1_data(dummy1),
        .rs2_data(dummy2)
    );

    isa_decoder uut (
        .clk(clk),
        .instruction(instruction),
        .opcode(opcode),
        .rd(rd),
        .imm(imm),
        .rs1_value(rs1_value),
        .rs2_value(rs2_value)
    );

    // Clock generator
    always #5 clk = ~clk;

    initial begin
        clk = 0;

        // Write values into registers
        write_to_register(4'd3, 32'd45);  // r3 = 45
        write_to_register(4'd5, 32'd77);  // r5 = 77

        // Simulate instruction: opcode=0000, rd=0001, rs1=0011, rs2=0101 (r3, r5)
        instruction = {4'b0000, 4'b0001, 4'd3, 4'd5, 16'd123};

        #10;

        $display("Instruction = %b", instruction);
        $display("Opcode: %b", opcode);
        $display("rs1_value: %d", rs1_value); // should be 45
        $display("rs2_value: %d", rs2_value); // should be 77

        if (rs1_value === 32'd45 && rs2_value === 32'd77)
            $display("PASS");
        else
            $display("FAIL");

        $finish;
    end

    task write_to_register(input [3:0] reg_index, input [31:0] value);
        begin
            reg_write = 1;
            rd_write = reg_index;
            write_data = value;
            #10;
            reg_write = 0;
            #10;
        end
    endtask
endmodule
