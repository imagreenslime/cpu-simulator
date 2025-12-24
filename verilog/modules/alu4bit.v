module alu4bit(
    input wire [3:0] a,
    input wire [3:0] b,
    input wire [2:0] opcode,
    output reg [3:0] result,
    output wire zero
    );

always @(*) begin
        case (opcode)
            3'b000: result = a & b;     // AND
            3'b001: result = a | b;     // OR
            3'b010: result = a + b;     // ADD
            3'b011: result = a - b;     // SUB
            3'b100: result = ~a;        // NOT a
            default: result = 4'b0000;
        endcase
    end

    assign zero = (result == 4'b0000);

endmodule
    