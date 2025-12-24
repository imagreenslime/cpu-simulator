`timescale 1ns/1ps

module test_alu4bit;
    reg [3:0] a, b;
    reg [2:0] opcode;
    wire [3:0] result;
    wire zero;

    alu4bit uut (
        .a(a),
        .b(b),
        .opcode(opcode),
        .result(result),
        .zero(zero)
    );

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, test_alu4bit);
        $monitor("opcode=%b a=%d b=%d -> result=%d, zero=%b", opcode, a, b, result, zero);

        // Test AND
        a = 4'b1100; b = 4'b1010; opcode = 3'b000; #10;
        // Test OR
        a = 4'b1100; b = 4'b1010; opcode = 3'b001; #10;
        // Test ADD
        a = 4'b0011; b = 4'b0101; opcode = 3'b010; #10;
        // Test SUB
        a = 4'b1000; b = 4'b1000; opcode = 3'b011; #10;
        // Test NOT
        a = 4'b1100; b = 4'b0000; opcode = 3'b100; #10;

        $finish;
    end
endmodule
