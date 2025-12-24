module instruction_memory (
    input wire [7:0] address,
    output wire [7:0] instruction
);

    reg [7:0] memory [0:255];
    initial begin
        // Initialize the memory with some instructions
        memory[0] = 8'b00000001;
        memory[1] = 8'b00000010;
        memory[2] = 8'b00000011;
        // Add more instructions as needed
        
    end

    assign instruction = memory[address];
endmodule