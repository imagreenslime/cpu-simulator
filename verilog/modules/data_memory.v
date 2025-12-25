module data_memory (
    input wire clk,
    input wire mem_read,
    input wire mem_write,
    input wire [31:0] address,
    input wire [31:0] write_data,
    output reg [31:0] read_data
);

    // 1K words = 4KB memory
    reg [31:0] memory [0:1023];

    // READ logic (combinational read)
    always @(*) begin
        if (mem_read) begin
            read_data = memory[address]; // word-aligned
        end else begin
            read_data = 32'd0;
        end
    end

    // WRITE logic (synchronous)
    always @(posedge clk) begin
        if (mem_write) begin
            memory[address[11:2]] <= write_data; // word-aligned
        end
    end

endmodule
