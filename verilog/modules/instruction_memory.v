module instruction_memory (
    input wire [31:0] address,
    output wire [31:0] instruction
);

    reg [31:0] memory [0:255];
    initial begin
        // Initialize the memory with some instructions
        memory[0] = 32'h22000017; // add r2 => 23
        memory[1] = 32'h26200017; // add r6 => 23
        memory[2] = 32'h26600017; // add r6 => 23
        memory[3] = 32'h42020003; // st r2 -> 3
        memory[4] = 32'h33000003; // ld r3 <= 3
        memory[5] = 32'h28330002;
        memory[6] = 32'h50000003; // beq r0, r0, +2 BROKEN
        memory[7] = 32'h34000003; // ld r4 <= 4
        memory[8] = 32'h25400005; // add r5 = r4 + 5
        memory[9] = 32'h60000004; //HALT
        // Add more instructions as needed
        
    end

    assign instruction = memory[address];
endmodule