# Via Honoris

Via Honoris is a full-stack implementation of a computing system, spanning from
the RTL description of the hardware  all the way up to the system software
required to manage it. The goal is to consolidate the computer architecture,
hardware design, and programming knowledge gained throughout my university
journey by applying it to a practical end-to-end project.

![Banner](assets/banner.png){ align=left }

The stack includes:

- [Virtus-RV]: A 5-stage RISC-V CPU implemented in SystemVerilog.
- Operating System: Initial port of FreeRTOS, followed by a custom OS (coming soon).
- Applications: Demo programs for system-level testing (coming soon).

Developed as part of the [Honors Academy] at TU Eindhoven.


[Virtus-RV]: cpu/cpu/
[Honors Academy]: https://educationguide.tue.nl/programs/honors-academy

## Getting Started

The root `Makefile` orchestrates the software compilation and deployment
workflow. The specific software payload for simulation or FPGA deployment is
defined by the `FW` variable, pointing to the target assembly file, C file or
application directory.

- `make sim FW=<path>`: Compiles the specified software and simulates its
execution on the Verilator hardware model.
- `make prog FW=<path>`: Compiles the software, generates the FPGA
bitstream (integrating the binary into block RAM), and flashes it to the
connected ECP5 board.
- `make clean`: Removes all build artifacts across the entire project,
including Verilator simulation builds, bitstreams, and compiled binaries.

Note: For RTL verification and compliance testing, refer to the [CPU Build
System section].

[CPU Build System section]: cpu/cpu/#build-system

