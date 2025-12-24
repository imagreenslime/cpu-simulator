module pc (
    input wire clk,
    input wire reset,
    input wire load_en,
    input wire [7:0] d,
    output reg [7:0] q
);

    always @(posedge clk or posedge reset) begin
        if (reset) 
            q <= 8'b00000000;
        else if (load_en)
            q <= d;
        else
            q <= q + 1;
    end
endmodule