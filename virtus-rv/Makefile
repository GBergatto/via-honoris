.PHONY: all verify rvtests clean tb fpga waves

# --- Configuration Variables ---
MODULE ?= hp_soc
TB     ?= $(MODULE)
WAVE   ?= $(PROG)

# Resolve testbench source from a stem (e.g. TB=regfile -> tb/regfile_tb.cpp)
TB_CPP := $(firstword $(wildcard tb/$(TB)*.cpp tb/$(TB)*.cc))

ifneq ($(MAKECMDGOALS),clean) # always allow "make clean"
ifeq ($(TB_CPP),)
$(error No C++ testbench found matching "$(TB)*.cpp" in tb/)
endif
endif

# Default target
all: verify

# Run Verilator testbench
verify:
	@echo ">>> Running Verilator testbench..."
	$(MAKE) -C tb MODULE=$(MODULE) TB=$(notdir $(TB_CPP))

# Run official riscv-tests (rv32ui)
rvtests:
	@echo ">>> Running rv32ui riscv-tests..."
	$(MAKE) -C tb MODULE=hp_soc TB=riscv_tests_tb.cpp

# Open GTKWave
waves:
	@echo ">>> Looking for waveform for: $(WAVE)"
	@VCD_PATH=$$(find tb/logs/waves -name "$(WAVE).vcd" | head -n 1); \
		if [ -z "$$VCD_PATH" ]; then \
		echo "Error: Could not find $$VCD_PATH. Run tests or simulation first."; \
		else \
		echo "Opening $$VCD_PATH with template tb/hp_soc.gtkw..."; \
		gtkwave $$VCD_PATH tb/hp_soc.gtkw > /dev/null 2>&1 & \
		fi

# Clean everything
clean:
	@echo ">>> Cleaning all directories..."
	$(MAKE) -C tb clean
	$(MAKE) -C fpga clean

