#include <iostream>
#include <vector>
#include <cassert>
#include "cpu.hpp"
#include "isa.hpp"
#include "cache.hpp"
#include "cache.cpp"
#include "cpu.cpp"

// THINGS I WANT TO ADD:
// better cache -> last recently used eviction

int main() {

    using Op = Opcode;
    printf("hello cpu test\n\n");

    std::vector<Instruction> prog = {
    {Opcode::ADDI,  3, 0, 0, 1},  // x0 = 
    {Opcode::STORE, 3, 1, 0, 0},  // mem[0] = 1
    {Opcode::LOAD,  1, 0, 0, 0},  // x1 = mem[0]
    {Opcode::ADD,   2, 1, 1, 0},  // x2 = x1 + x1
    {Opcode::HALT}
    };

    CPU cpu(prog);
    cpu.run();

    // === Assertions  ===

    printf("All tests passed.\n\n");
    int32_t val = cpu.mem_word(1);
    printf("memory[1] = %d\n", val);


    // === Optional debug dump ===
    printf("Register Dump.\n\n");
    for (int i = 0; i < 8; i++) {
        printf("x%d = %d\n", i, cpu.reg(i));
    }

    return 0;
}
