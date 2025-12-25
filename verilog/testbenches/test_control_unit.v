`timescale 1ns / 1ps
`include "./modules/control_unit.v"
module test_control_unit;

    // Inputs
    reg [3:0] opcode;

    // Outputs
    wire [1:0] category;

    // Instantiate the control_unit
    control_unit uut (
        .opcode(opcode),
        .category(category)
    );

    // Test procedure
    initial begin
        $display("Testing control_unit");
        $display("OPCODE | CATEGORY | EXPECTED | RESULT");
        
        // ALU: 0000 (ADD), 0001 (SUB), 0010 (ADDI)
        test_case(4'b0000, 2'b00);
        test_case(4'b0001, 2'b00);
        test_case(4'b0010, 2'b00);

        // MEMORY: 0011 (LOAD), 0100 (STORE)
        test_case(4'b0011, 2'b01);
        test_case(4'b0100, 2'b01);

        // CONTROL: 0101 (BEQ), 0111 (JAL)
        test_case(4'b0101, 2'b10);
        test_case(4'b0111, 2'b10);

        // SYSTEM: 0110 (HALT), 1000 (NOP)
        test_case(4'b0110, 2'b11);
        test_case(4'b1000, 2'b11);

        // UNKNOWN OPCODE: should default to SYSTEM (2'b11)
        test_case(4'b1111, 2'b11);
        test_case(4'b1010, 2'b11);

        $display("Testbench finished.");
        $finish;
    end

    // Task for comparing outputs
    task test_case;
        input [3:0] op;
        input [1:0] expected;
        begin
            opcode = op;
            #5; // Wait for combinational logic to propagate

            if (category === expected)
                $display("  %b   |    %b    |   %b    | PASS", op, category, expected);
            else
                $display("  %b   |    %b    |   %b    | FAIL", op, category, expected);
        end
    endtask

endmodule
