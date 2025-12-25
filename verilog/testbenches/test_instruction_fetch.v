`timescale 1ns/1ps

module test_instruction_fetch;
    reg clk, reset, load_en;
    wire [31:0] current_instruction;

    instruction_fetch uut (
        .clk(clk),
        .reset(reset),
        .load_en(load_en),
        .current_instruction(current_instruction)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, test_instruction_fetch);
        $monitor("time=%t | clk=%b reset=%b load_en=%b -> instr=%b", 
                  $time, clk, reset, load_en, current_instruction);

        clk = 0;
        reset = 1; load_en = 0; #10;   // Reset PC and IR
        reset = 0; load_en = 1; #10;   // Load instruction from mem[0]
        load_en = 1; #10;              // Load next instruction (mem[1])
        load_en = 1; #10;              // Load mem[2]
        load_en = 1; #10;              // Load mem[3]
        $finish;
    end
endmodule
