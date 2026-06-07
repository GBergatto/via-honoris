# Virtus-RV

Virtus-RV is a 5-stage RISC-V processor implementation supporting the RV32I
instruction set, intended for FPGA deployment. For a detailed breakdown of the
microarchitecture and pipeline stages, refer to the [Architecture] page. This
core, which follows the classical pipeline architecture found in computer
architecture textbooks, is wrapped into an SoC to allow it to interact with
external hardware and be deployed on an FPGA board.

[Architecture]: core/microarchitecture/

## Project Structure

The `virtus-rv/` directory contains the processor's implementation and build
system:

- `rtl/`: SystemVerilog source code for the RISC-V processor.
- `tb/`: C++ Verilator testbenches used to validate the RTL code.
- `fpga/`: Top-level modules and configuration files for FPGA synthesis and
deployment.
- `Makefile`: Master build script that handles both simulation and FPGA
deployment by calling sub-folder Makefiles.

## Build System

The `Makefile` inside the `virtus-rv/` directory orchestrates the hardware build
workflow.

By default, the target RTL module is set to `hp_soc`, which can be overridden
using the `MODULE` variable. If you change the target module, you must run
`make clean` first to clear out any stale Verilator object files. Finally, for
debugging, the `WAVE` variable allows for quickly opening the simulation traces
in GTKWave, using the predefined signal layout found in `tb/hp_soc.gtkw`.

- `make verify` (or `make`): Runs the C++ Verilator testbench to validate the
RTL for the specified `MODULE`.
- `make rvtests`: Runs the official `rv32ui` RISC-V compliance test suite to
verify the core's correct implementation.
- `make waves WAVE=<name>`: Locates the `.vcd` simulation trace for the
specified test and opens it in GTKWave for debugging.
- `make clean`: Removes all build artifacts across the testbench and FPGA
directories.

