`timescale 1ns/1ps

module test_d_flip_flop;
    reg clk, reset, d;
    wire q;

    d_flip_flop uut (
        .clk(clk),
        .reset(reset),
        .d(d),
        .q(q)
    );

always #5 clk = ~clk;
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, test_d_flip_flop);
        $monitor("time=%t | clk=%b reset=%b d=%b -> q=%b", $time, clk, reset, d, q);

        clk = 0;
        d = 0;
        reset = 0;
        #10;
        d = 1;
        reset = 0;
        #10;
        d = 0;
        reset = 1;
        #10;
        d = 1;
        reset = 1;
        #10;
        $finish;
    end
endmodule