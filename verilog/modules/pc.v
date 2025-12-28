module pc (
    input wire clk,
    input wire reset,
    input wire load_en,
    input wire en,
    input wire [31:0] d,
    output reg [31:0] q
    
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            q <= 32'h00000000;
        end
        else if (load_en ) begin
            q <= d;
            $display("changing PC: %0d", d);
        end
        else if (!en) begin
            q <= q;                // HOLD (stall)
        end
        else begin
            q <= q + 1;
        end
    end
endmodule