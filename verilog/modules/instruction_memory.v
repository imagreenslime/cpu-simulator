module instruction_memory (
    input wire [31:0] address,
    output wire [31:0] instruction
);

    reg [31:0] memory [0:255];
    initial begin
        // Initialize the memory with some instructions
        memory[0] = 32'h23000001;
        memory[1] = 32'h28000002;
        memory[2] = 32'h2a000003;
        memory[3] = 32'h60000004; //HALT
        // Add more instructions as needed
        
    end

    assign instruction = memory[address];
endmodule