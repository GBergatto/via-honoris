# ==============================================================================
# FPGA Deployment Makefile
# ==============================================================================

PROJ = custom_riscv
RTL_DIR  = ../rtl
FW_DIR   = ../fw

SV_FILES = \
    $(RTL_DIR)/core_types_pkg.sv \
    $(filter-out $(RTL_DIR)/core_types_pkg.sv, $(wildcard $(RTL_DIR)/*.sv)) \
    top_ecp5evn.sv

HEX_FILE = $(FW_DIR)/firmware.hex
LPF_FILE = ecp5evn.lpf
FLATTENED_V = flattened_cpu.v

PNR_FLAGS = --um5g-85k --package CABGA381

.PHONY: all bitstream prog clean

all: bitstream

$(FLATTENED_V): $(SV_FILES)
	@echo "--- Transpiling SystemVerilog ---"
	sv2v $^ > $@

$(PROJ).json: $(FLATTENED_V) $(HEX_FILE)
	@echo "--- Synthesizing ---"
	yosys -p "read_verilog $(FLATTENED_V); synth_ecp5 -top top_ecp5evn -json $@"

$(PROJ).config: $(PROJ).json $(LPF_FILE)
	@echo "--- Placing and Routing ---"
	nextpnr-ecp5 --json $< --textcfg $@ $(PNR_FLAGS) --lpf $(LPF_FILE)

$(PROJ).bit: $(PROJ).config
	@echo "--- Packing Bitstream ---"
	ecppack $< $@

bitstream: $(PROJ).bit

prog: $(PROJ).bit
	@echo "--- Flashing ECP5 Board ---"
	openFPGALoader -b ecp5_evn $<

clean:
	rm -f $(FLATTENED_V) *.json *.config *.bit
