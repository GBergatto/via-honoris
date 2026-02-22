MODULE ?= hp_soc
PROG   ?= counter
WAVE   ?= $(PROG)
.PHONY: all sim sim-fw bitstream prog clean fw tb fpga waves

# Default target
all: verify

# 1. Build firmware only
fw:
	@echo ">>> Building Firmware ($(PROG))..."
	$(MAKE) -C fw PROG=$(PROG)

# 2. Run Verilator testbench
verify:
	@echo ">>> Running Verilator testbench..."
	$(MAKE) -C tb MODULE=$(MODULE)

# 3. Simulate firmware
sim: fw
	@echo ">>> Simulating Firmware ($(PROG))..."
	$(MAKE) -C tb MODULE=$(MODULE) SIM_ARGS="--fw $(PROG)"

# 4. Build FPGA bitstream
bitstream: fw
	@echo ">>> Building FPGA Bitstream..."
	$(MAKE) -C fpga bitstream

# 5. Flash FPGA
prog: fw
	@echo ">>> Flashing FPGA..."
	$(MAKE) -C fpga prog

# 6. Open GTKWave
waves:
	@echo ">>> Looking for waveform for: $(WAVE)"
	@VCD_PATH=$$(find tb/logs/waves -name "$(WAVE).vcd" | head -n 1); \
		if [ -z "$$VCD_PATH" ]; then \
		echo "Error: Could not find $$VCD_PATH. Run tests or simulation first."; \
		else \
		echo "Opening $$VCD_PATH with template tb/hp_soc.gtkw..."; \
		gtkwave $$VCD_PATH tb/hp_soc.gtkw > /dev/null 2>&1 & \
		fi

# 7. Clean everything
clean:
	@echo ">>> Cleaning all directories..."
	$(MAKE) -C fw clean
	$(MAKE) -C tb clean
	$(MAKE) -C fpga clean
