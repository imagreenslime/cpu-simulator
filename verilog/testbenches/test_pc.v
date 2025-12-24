`timescale 1ns/1ps

module test_pc;
    reg clk, reset, load_en;
    reg [7:0] d;
    wire [7:0] q;

    pc uut (
        .clk(clk),
        .reset(reset),
        .load_en(load_en),
        .d(d),
        .q(q)
    );

    // Clock generator
    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, test_pc);
        $monitor("time=%t | clk=%b reset=%b load_en=%b d=%d -> q=%d", $time, clk, reset, load_en, d, q);

        clk = 0;
        reset = 1; load_en = 0; d = 8'd0; #10;    // Reset → PC should be 0

        reset = 0; load_en = 0; #20;              // PC should increment

        load_en = 1; d = 8'd100; #10;             // Load jump to 100
        load_en = 0; #20;                         // PC should increment from 100 → 101 → 102

        $finish;
    end
endmodule
