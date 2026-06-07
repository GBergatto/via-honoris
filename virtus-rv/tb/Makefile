# ==============================================================================
# Simulation Makefile (Verilator)
# ==============================================================================

MODULE ?= virtus_soc
TB ?= $(MODULE)_tb.cpp
SIM_ARGS ?=

VERILATOR := verilator
RTL_DIR := ../rtl
FW_DIR := ../fw
BUILD_DIR   := build

# Automatically find RTL and TB sources
PKG_FILES   := $(RTL_DIR)/core_types_pkg.sv
SRC_VERILOG := $(filter-out $(PKG_FILES), $(wildcard $(RTL_DIR)/*.v $(RTL_DIR)/*.sv))
TB_NAME     := $(basename $(notdir $(TB)))
OBJ_DIR     := $(BUILD_DIR)/obj_dir_$(TB_NAME)
STAMP_FILE  := $(BUILD_DIR)/.stamp.verilate.$(MODULE).$(TB_NAME)

ifneq ($(MAKECMDGOALS),clean) # always allow "make clean"
ifeq ($(wildcard $(TB)),)
$(error Testbench file "$(TB)" not found in tb/)
endif
endif

ALL_SOURCES := $(PKG_FILES) $(SRC_VERILOG) $(TB)

VERILATOR_FLAGS += -cc --exe
VERILATOR_FLAGS += -x-assign fast
VERILATOR_FLAGS += -Wall
VERILATOR_FLAGS += --LDFLAGS -lyaml-cpp
VERILATOR_FLAGS += --trace-vcd
VERILATOR_FLAGS += --assert
VERILATOR_FLAGS += --coverage
VERILATOR_FLAGS += -Mdir $(OBJ_DIR)

ifeq ($(MODULE),virtus_soc)
	VERILATOR_FLAGS += -GINIT_FILE='"roms/firmware.hex"'
endif

.PHONY: all verilate build simulate coverage clean

all: simulate

verilate: .stamp.verilate

$(STAMP_FILE): $(ALL_SOURCES)
	@echo "### VERILATING $(MODULE) ###"
	@mkdir -p $(BUILD_DIR)
	$(VERILATOR) $(VERILATOR_FLAGS) $(ALL_SOURCES) --top-module $(MODULE)
	@touch $(STAMP_FILE)

.stamp.verilate: $(STAMP_FILE)

build: $(OBJ_DIR)/V$(MODULE)

$(OBJ_DIR)/V$(MODULE): .stamp.verilate
	@echo "### BUILDING SIM ###"
	$(MAKE) -C $(OBJ_DIR) -f V$(MODULE).mk V$(MODULE)

simulate: build
	@echo "### SIMULATING ###"
	@rm -rf logs
	@mkdir -p logs/waves
	@$(OBJ_DIR)/V$(MODULE) +trace $(SIM_ARGS)

coverage:
	@echo "### COVERAGE ###"
	@rm -rf logs/annotated
	verilator_coverage --annotate logs/annotated logs/coverage.dat

clean:
	rm -rf $(BUILD_DIR) logs *.log *.dmp *.vcd coverage.dat core
