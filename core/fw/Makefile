# ==============================================================================
# Firmware Makefile (.s -> .hex)
# ==============================================================================

PROG ?= counter

SRC      = $(PROG).s
ELF_FILE = $(PROG).elf
HEX_FILE = firmware.hex

PREFIX = riscv32-unknown-elf-

.PHONY: all clean

all: $(HEX_FILE)

# 1. Compile Source to ELF
$(ELF_FILE): $(SRC)
	@echo "--- Compiling $(SRC) ---"
	$(PREFIX)gcc -march=rv32i -mabi=ilp32 -nostdlib -Ttext 0x0 -o $@ $<

# 2. Extract Verilog Hex directly from ELF
$(HEX_FILE): $(ELF_FILE)
	@echo "--- Generating Verilog Hex ---"
	$(PREFIX)objcopy -O verilog --verilog-data-width=4 $< $@

clean:
	rm -f *.elf *.bin *.hex
