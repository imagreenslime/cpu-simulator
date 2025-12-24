TOP=testbenches/test_and_gate.v
MODULES=modules/and_gate.v
OUTPUT=test_and_gate

all: run

compile:
	iverilog -o $(OUTPUT).vvp $(TOP) $(MODULES)

run: compile
	vvp $(OUTPUT).vvp

waveform: run
	gtkwave wave.vcd &

clean:
	rm -f *.vvp *.vcd
