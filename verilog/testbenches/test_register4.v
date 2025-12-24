`timescale 1ns/1ps

module test_register4;
    reg clk, reset, we;
    reg [3:0] d;
    wire [3:0] q;

    register4 uut (
        .clk(clk),
        .reset(reset),
        .we(we),
        .d(d),
        .q(q)
    );

always #5 clk = ~clk;
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, test_register4);
        $monitor("time=%t | clk=%b reset=%b we=%b d=%b -> q=%b", $time, clk, reset, we, d, q);

        clk = 0; reset = 1; we = 0; d = 4'b0000; #10;

        // Release reset, still no write
        reset = 0; we = 0; d = 4'b1010; #10;

        // Write enabled → register should store `d` on clk edge
        we = 1; d = 4'b1010; #10;

        // Change input, but no write → q should stay the same
        we = 0; d = 4'b1111; #10;

        // Enable write again with new value
        we = 1; d = 4'b0011; #10;

        // Reset → q should go to 0
        reset = 1; #10;

        $finish;
    end
endmodule