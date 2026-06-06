# FPGA toolchain

To build, place, route, and flash the SoC, this project relies on a fully
open-source hardware toolchain. All necessary tools are bundled within the [OSS
CAD Suite] (available via release binaries or as `oss-cad-suite-build-bin` on
the Arch User Repository). For more details, refer to the official
documentation of each tool.

[OSS CAD Suite]: https://github.com/YosysHQ/oss-cad-suite-build

## Build Pipeline

The build pipeline relies on the following tools:

1. **sv2v:** A SystemVerilog to Verilog converter. It flattens the entire SoC
   source code into a single, standard Verilog-2005 file that can be safely fed
   to the synthesis suite.
2. **Yosys:** The core synthesis suite. It takes the Verilog output from `sv2v`
   and synthesizes it into a generic, architecture-independent gate-level
   netlist.
3. **nextpnr:** The place and route (PnR) tool. It takes the netlist from Yosys
   and maps the logic to the physical cells and routing fabric of the target
   FPGA.
4. **openFPGALoader:** A universal utility for programming FPGAs. It handles
   the final step of flashing the generated bitstream onto the physical board
   over USB.

## Architecture-Specific Components

While Yosys generates a generic logic netlist, turning that logic into a
physical working bitstream requires specific knowledge of the target FPGA's
internal layout. Regardless of the board you use, you will need three
architecture-specific components to complete the pipeline:

- **Place and Route (PnR) Backend:** A target-specific build of `nextpnr` that
  understands how to map generic logic gates to the exact lookup tables (LUTs),
  flip-flops, and routing matrices of your chip.
- **Bitstream Packer:** A tool that relies on a reverse-engineered hardware
  database to translate the routed design into the proprietary binary bitstream
  format required to configure the silicon.
- **Constraint File:** A text file used to manually map the top-level Verilog
  I/O ports to the physical pins on the specific board package (e.g., routing the
  SPI controller to a specific header pin, controlling onboard LEDs).

Here is the toolchain mapping for common open-source supported targets:

|**Target FPGA Family**|**PnR Backend**|**Bitstream Packer (Database)**|**Constraint Format**|
|---|---|---|---|
|**Lattice ECP5**|`nextpnr-ecp5`|`ecppack` (Project Trellis)|`.lpf`|
|**Lattice iCE40**|`nextpnr-ice40`|`icepack` (Project IceStorm)|`.pcf`|
|**Gowin**|`nextpnr-gowin`|`gowin_pack` (Project Apicula)|`.cst`|

