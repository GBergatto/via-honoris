.PHONY: sim prog clean

FW ?= sw/baremetal/counter.s

# Remove 'sw/' prefix if it's passed
SW_FW = $(patsubst sw/%,%,$(FW))
PROG_NAME = $(basename $(notdir $(patsubst %/,%,$(SW_FW))))

sim:
	@echo ">>> Building software: $(FW)..."
	$(MAKE) -C sw FW=$(SW_FW)
	@echo ">>> Simulating on Virtus-RV..."
	$(MAKE) -C virtus-rv sim PROG=$(PROG_NAME)

prog:
	@echo ">>> Building software: $(FW)..."
	$(MAKE) -C sw FW=$(SW_FW)
	@echo ">>> Building FPGA Bitstream..."
	$(MAKE) -C virtus-rv bitstream PROG=$(PROG_NAME)
	@echo ">>> Flashing FPGA..."
	$(MAKE) -C virtus-rv prog PROG=$(PROG_NAME)

clean:
	@echo ">>> Cleaning Virtus-RV..."
	$(MAKE) -C virtus-rv clean
	@echo ">>> Cleaning Software..."
	$(MAKE) -C sw clean
