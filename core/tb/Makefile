# ==============================================================================
# Simulation Makefile (Verilator)
# ==============================================================================

MODULE ?= hp_soc
SIM_ARGS ?=

VERILATOR = verilator
RTL_DIR = ../rtl
FW_DIR = ../fw

# Automatically find RTL and TB sources
PKG_FILES   := $(RTL_DIR)/core_types_pkg.sv
SRC_VERILOG := $(filter-out $(PKG_FILES), $(wildcard $(RTL_DIR)/*.v $(RTL_DIR)/*.sv))
TB_FILE     := $(wildcard $(MODULE)*.cpp)

ifneq ($(MAKECMDGOALS),clean) # always allow "make clean"
ifeq ($(wildcard $(TB_FILE)),)
$(error No C++ testbench found matching "$(MODULE)*.cpp" in tb/)
endif
endif

ALL_SOURCES := $(PKG_FILES) $(SRC_VERILOG) $(TB_FILE)

VERILATOR_FLAGS += -cc --exe
VERILATOR_FLAGS += -x-assign fast
VERILATOR_FLAGS += -Wall
VERILATOR_FLAGS += --LDFLAGS -lyaml-cpp
VERILATOR_FLAGS += --trace-vcd
VERILATOR_FLAGS += --assert
VERILATOR_FLAGS += --coverage
VERILATOR_FLAGS += -Mdir obj_dir

ifeq ($(MODULE),hp_soc)
	VERILATOR_FLAGS += -GINIT_FILE='"roms/firmware.hex"'
endif

.PHONY: all verilate build simulate coverage clean

all: simulate

verilate: .stamp.verilate

.stamp.verilate: $(ALL_SOURCES)
	@echo "### VERILATING $(MODULE) ###"
	$(VERILATOR) $(VERILATOR_FLAGS) $(ALL_SOURCES) --top-module $(MODULE)
	@touch .stamp.verilate

build: obj_dir/V$(MODULE)

obj_dir/V$(MODULE): .stamp.verilate
	@echo "### BUILDING SIM ###"
	$(MAKE) -C obj_dir -f V$(MODULE).mk V$(MODULE)

simulate: build
	@echo "### SIMULATING ###"
	@rm -rf logs
	@mkdir -p logs/waves
	@obj_dir/V$(MODULE) +trace $(SIM_ARGS)

coverage:
	@echo "### COVERAGE ###"
	@rm -rf logs/annotated
	verilator_coverage --annotate logs/annotated logs/coverage.dat

clean:
	rm -rf .stamp.* obj_dir logs *.log *.dmp *.vcd coverage.dat core
