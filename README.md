# Via Honoris

This project features a 5-stage pipelined RISC-V processor implemented in
SystemVerilog and deployed on an FPGA board. For comprehensive implementation
details, simulation guides, and synthesis instructions, refer to the
[documentation website](https://gbergatto.github.io/via-honoris/).

## Demo

Here is a demo of Tetris written in bare-metal C, deployed on a Lattice ECP5
evaluation board. The software drives an ILI9341 LCD screen and reads inputs
from breadboard buttons.

![Tetris Demo](docs/assets/tetris.gif)

## Next Steps

- Expand ISA support to include more RISC-V extensions (e.g., RV32M).
- Deploy FreeRTOS on the board to test hardware stability under a real-time kernel.
- Write a lightweight xv6-inspired operating system from scratch.

