`timescale 1ns/1ps

module test_instruction_memory;
    reg [7:0] address;
    wire [7:0] instruction;

    instruction_memory uut (
        .address(address),
        .instruction(instruction)
    );

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, test_instruction_memory);
        $monitor("address = %d -> instruction = %b", address, instruction);

        address = 8'd0; #10;
        address = 8'd1; #10;
        address = 8'd2; #10;
        address = 8'd3; #10;
        address = 8'd4; #10;

        $finish;
    end
endmodule
