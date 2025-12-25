`timescale 1ns/1ps

module test_instruction_register;
    reg clk, reset, load_en;
    reg [15:0] instruction_in;
    wire [15:0] instruction_out;

    instruction_register uut (
        .clk(clk),
        .reset(reset),
        .load_en(load_en),
        .instruction_in(instruction_in),
        .instruction_out(instruction_out)
    );

    // Generate clock
    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, test_instruction_register);
        $monitor("time=%t | clk=%b reset=%b load_en=%b in=%b -> out=%b", 
                  $time, clk, reset, load_en, instruction_in, instruction_out);

        // Initial states
        clk = 0; reset = 1; load_en = 0; instruction_in = 16'b0000000000000000; #10;

        // Release reset, load first instruction
        reset = 0; load_en = 1; instruction_in = 16'b0000000011001100; #10;

        // No load → instruction_out holds its value
        load_en = 0; instruction_in = 16'b0000000000001111; #10;

        // Load new instruction
        load_en = 1; instruction_in = 16'b0000000011110000; #10;

        $finish;
    end
endmodule
