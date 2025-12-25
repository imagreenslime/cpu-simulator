module instruction_register (
    input wire [31:0] instruction_in,
    input wire clk,
    input wire reset,
    input wire load_en,
    output reg [31:0] instruction_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            instruction_out <= 32'h00000000; // Initialize instruction_out to 0 on reset
        end else if (load_en) begin
            instruction_out <= instruction_in;
        end
    end

    
endmodule