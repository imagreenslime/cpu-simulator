module control_unit (
    input wire [3:0] opcode,
    output reg [1:0] category
);
    always @(*) begin
        case (opcode)
            4'b0000, 4'b0001, 4'b0010: category = 2'b00; // ALU instruction
            4'b0011, 4'b0100: category = 2'b01; // MEMORY instruction
            4'b0101, 4'b0111: category = 2'b10; // Control instruction
            4'b0110, 4'b1000: category = 2'b11; // Halt instruction
            default: category = 2'b11; // Default to halt if opcode is not recognized
        endcase
    end
endmodule