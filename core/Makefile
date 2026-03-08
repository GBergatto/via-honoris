.PHONY: all sim bitstream prog clean fw tb fpga waves

MODULE ?= hp_soc
PROG   ?= counter

all: sim

# 1. Build firmware only
fw:
	@echo ">>> Building Firmware..."
	$(MAKE) -C fw PROG=$(PROG)

# 2. Run Verilator simulation
sim: fw
	@echo ">>> Running Simulation..."
	$(MAKE) -C tb MODULE=$(MODULE)

# 3. Build FPGA bitstream
bitstream: fw
	@echo ">>> Building FPGA Bitstream..."
	$(MAKE) -C fpga bitstream

# 4. Flash FPGA
prog: fw
	@echo ">>> Flashing FPGA..."
	$(MAKE) -C fpga prog

# 5. Clean everything
clean:
	@echo ">>> Cleaning all directories..."
	$(MAKE) -C fw clean
	$(MAKE) -C tb clean
	$(MAKE) -C fpga clean

