# HP Core

This directory contains an educational implementation of a 5-stage pipelined
RISC-V RV32I CPU core, written in SystemVerilog and tested using a C++
testbench via Verilator.

The `rtl` directory contains the SystemVerilog implementation of the core.
The `tb` directory contains the corresponding C++ testbenches.

## Requirements

- Verilator  
- yaml-cpp  
- riscv32-unknown-elf toolchain  
- GTKWave (optional, for viewing waveforms)

## Building

Running `make` from this directory will:

1. Verilate all SystemVerilog sources  
2. Build the C++ testbench  
3. Assemble all tests in `tb/roms/`  
4. Run the testbench over all ROMs  
5. Generate logs in `logs/` and VCD waveform dumps in `logs/waves/`

Running `make` with a custom `MODULE` value allows testing specific modules.  
For example, to run the instruction memory testbench:

```
make MODULE=imem
```

Run `make clean` first when switching modules to remove stale verilated files.

