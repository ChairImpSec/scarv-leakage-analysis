.PHONY: clean build sim synth all

# TARGET NAME
TOPMODULE 			:= secure_frv_masked_and
TESTBENCH			:= $(TOPMODULE)

# PORT NAMES
CLOCK_NAME 			:= g_clk

# DESIGN TYPE <verilog/vhdl>
DESIGN_TYPE 		:= verilog

# DIRECTORIES
SOURCE_DIR	 		:= ./src
SIM_RESULT_DIR 		:= ./sim

# COMPILER/LINKER OPTIONS
IVERILOG_FLAGS 		:= -g2005-sv

# SYNTHESIS and SIMULATION RESULT
SYNTH_RESULT 		:= $(SIM_RESULT_DIR)/$(TOPMODULE).vvp
SIMULATION_RESULT 	:= $(SIM_RESULT_DIR)/$(TOPMODULE).vcd

all: sim

build: $(SYNTH_RESULT)

sim: $(SIMULATION_RESULT)

$(SYNTH_RESULT): $(SOURCE_DIR)
	mkdir -p $(SIM_RESULT_DIR)
	iverilog  $(IVERILOG_FLAGS) -o $(SYNTH_RESULT) -s $(TESTBENCH) $(SOURCE_DIR)/*

$(SIMULATION_RESULT): $(SYNTH_RESULT)
	vvp $^

synth: sim
	echo "TODO: put here your invocation of your synthesiser."
	# ./../../synth.sh $(DESIGN_TYPE) $(CLOCK_NAME)

clean:
	rm $(SYNTH_RESULT) $(SIMULATION_RESULT)
	rm -f synthsis.log

