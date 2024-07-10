.PHONY: clean build sim synth all randomtests randomtesta test

# TARGET NAME
TOPMODULE 			:= wrapper_frv_masked_barith
TESTBENCH			:= tb_$(TOPMODULE)

# PORT NAMES
CLOCK_NAME 			:= g_clk

# DESIGN TYPE <verilog/vhdl>
DESIGN_TYPE 		:= verilog

# DIRECTORIES
SOURCE_DIR	 		:= ./src
SIM_RESULT_DIR 		:= ./sim
INCLUDE_DIR			:= ./inc

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
	cd $(SIM_RESULT_DIR) && vvp $(TOPMODULE).vvp

synth: sim
	# ./../../synth.sh $(DESIGN_TYPE) $(CLOCK_NAME)
	echo "TODO: put here your invocation of your synthesiser."

clean:
	rm $(SYNTH_RESULT) $(SIMULATION_RESULT)
	rm -f synthsis.log

randomtesta:
	cd ./prolead_configs/green-trans-fixed-random/ && ./run.sh

randomtests:
	cd ./prolead_configs/sub-green-trans-fixed-random && ./run.sh

test: randomtesta randomtests
