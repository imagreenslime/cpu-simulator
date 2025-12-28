# Pipelined RISC CPU in Verilog

This project implements a simplified, MIPS-like 5-stage pipelined CPU entirely in Verilog HDL, designed with:

Accurate instruction flow through classic pipeline stages:
IF → ID → EX → MEM → WB

The Verilog model was developed after a full-featured C++ simulator used to prototype pipeline behavior and cache performance.

---

## Verilog Features
- 5-stage CPU Pipeline
- Load-use hazard detection and stalling
- Data forwarding (EX→EX and MEM→EX paths)
- Pipeline flush on control hazards
- Waveform-debuggable control signals

## Verification
- Testbenches for each pipeline feature
- Assembly-style test programs (in Verilog hex format)
- Simulated using Icarus
- Observed via GTKWave waveform viewer

## Instruction Set
- ADD, SUB, ADDI
- LOAD, STORE
- BEQ, JAL
- NOP, HALT

## C++ Reference Model (Pre-Verilog Phase)
- The initial design phase included a C++ cycle-accurate simulator with:
- Instruction-level simulation
- Set-associative cache with LRU
- CPI and hazard statistics
- This model served as a reference for RTL validation

## Build and Run Verilog
```bash
iverilog -o cpu_test.vvp testbenches/test_cpu.v
vvp cpu_test.vvp
```
Add instructions in verilog/modules/instruction_memory.v

## Build and Run C++
```bash
cd src
g++ main.cpp -o sim
./sim
```