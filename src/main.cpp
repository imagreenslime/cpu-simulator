#include <iostream>
#include <vector>
#include <cassert>
#include "cpu.hpp"
#include "isa.hpp"
#include "cache.hpp"
#include "cache.cpp"
#include "cpu.cpp"

// THINGS I WANT TO ADD:
// Multi-Level Cache Hierarchy
// Convert to Verilog or SystemVerilog

std::vector<Instruction> generate_cache_test_program() {
    std::vector<Instruction> program;

    for (int i = 0; i < 40; ++i) {
        program.push_back({Opcode::LOAD, 1, 0, 0, i}); 
    }

    // End program
    program.push_back({Opcode::HALT});
    return program;
}

int main() {

    using Op = Opcode;
    printf("hello cpu test\n\n");

    std::vector<Instruction> prog = {
    {Opcode::ADDI,  3, 0, 0, 7},
    {Opcode::STORE, 3, 0, 0, 0},  
    {Opcode::LOAD,  1, 0, 0, 0},  

    {Opcode::HALT}
    };

    CPU cpu(prog);
    cpu.run();


    printf("All tests passed.\n\n");
    int32_t val = cpu.mem_word(0);
    printf("memory[0] = %d\n", val);


    // debug dump 
    printf("Register Dump.\n\n");
    for (int i = 0; i < 8; i++) {
        printf("x%d = %d\n", i, cpu.reg(i));
    }

    return 0;
}
