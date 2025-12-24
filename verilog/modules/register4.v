module register4 (
    input wire clk,
    input wire reset,
    input wire we,
    input wire [3:0] d,
    output reg [3:0] q
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            q[3:0] <= 4'b0000;
        end else if (we) begin
            q <= d;
        end
    end

endmodule   