.PHONY: clean build sim synth randomtest all test

#------------------------------------------
#  Adopt in the block below
#------------------------------------------
# TARGET NAME
TOPMODULE 			:= wrapper_frv_masked_shfrot
TESTBENCH			:= tb_$(TOPMODULE)

# PORT NAMES
CLOCK_NAME 			:= clk

# DESIGN TYPE <verilog/vhdl>
DESIGN_TYPE 		:= verilog

# -----------------------------------------

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
	cd $(SIM_RESULT_DIR) && vvp ../$(SYNTH_RESULT)

synth: $(SIMULATION_RESULT)
	# ./../../synth.sh $(DESIGN_TYPE) $(CLOCK_NAME)
	echo "TODO: put here your invocation of your synthesiser."

clean:
	rm $(SYNTH_RESULT) $(SIMULATION_RESULT)
	rm -f synthsis.log

randomtest:
	cd ./prolead/config/fixed-random/ && ./run.sh


test: randomtest
