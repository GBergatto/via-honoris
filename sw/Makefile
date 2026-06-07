# ==============================================================================
# Firmware Makefile (.c / .s -> .hex)
# ==============================================================================

FW ?= baremetal/counter.s

# Strip trailing slash if present
FW_CLEAN = $(patsubst %/,%,$(FW))

# Check if FW_CLEAN is a directory
ifeq ($(shell test -d $(FW_CLEAN) && echo dir),dir)
    PROG = $(notdir $(FW_CLEAN))
    SRC_C = $(wildcard $(FW_CLEAN)/*.c)
    SRC_S = $(wildcard $(FW_CLEAN)/*.s)
else
    # It's a file
    PROG = $(basename $(notdir $(FW_CLEAN)))
    ifeq ($(suffix $(FW_CLEAN)),.c)
        SRC_C = $(FW_CLEAN)
        SRC_S =
    else ifeq ($(suffix $(FW_CLEAN)),.s)
        SRC_C =
        SRC_S = $(FW_CLEAN)
    else
        $(error "Unsupported file extension for FW: $(FW_CLEAN)")
    endif
endif

BUILD_DIR = build
ELF_FILE = $(BUILD_DIR)/$(PROG).elf
HEX_FILE = $(BUILD_DIR)/firmware.hex

PREFIX = riscv32-unknown-elf-

.PHONY: all clean

all: $(HEX_FILE)

# Include library sources
LIB_C = $(wildcard libs/*.c)
LIB_S = $(wildcard libs/*.s)

ifeq ($(SRC_C),)
    # Pure assembly project
    SRC = $(SRC_S)
    CFLAGS_EXTRA = -Wl,--no-warn-rwx-segments
else
    # C project
    CRT0 = bsp/crt0.s
    SRC = $(CRT0) $(SRC_C) $(LIB_C)
    CFLAGS_EXTRA = -O2 -Ibsp -Ilibs -ffunction-sections -fdata-sections -fno-tree-loop-distribute-patterns -Wl,--gc-sections,--no-warn-rwx-segments
endif

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# 1. Compile Source to ELF
$(ELF_FILE): $(SRC) | $(BUILD_DIR)
	@echo "--- Compiling $(PROG) ---"
	$(PREFIX)gcc -march=rv32i_zicsr -mabi=ilp32 -nostdlib $(CFLAGS_EXTRA) -T bsp/link.ld -o $@ $^

# 2. Extract Verilog Hex directly from ELF
$(HEX_FILE): $(ELF_FILE) | $(BUILD_DIR)
	@echo "--- Generating Verilog Hex ---"
	$(PREFIX)objcopy --change-addresses -0x80000000 -O verilog --verilog-data-width=4 $< $@

clean:
	rm -rf $(BUILD_DIR)