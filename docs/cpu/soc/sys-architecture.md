# System Architecture

The SoC integrates the pipelined [RISC-V core] with a unified memory subsystem
and a suite of memory-mapped peripherals via a standard Wishbone interconnect.
This page details the system-level routing, bus arbitration, and the address
map for all attached hardware components, including the core timer (CLINT),
physical I/O (LEDs/Buttons), and the SPI display controller.

[RISC-V core]: ../core/microarchitecture/

## System Memory

The core implements a Harvard-style datapath with independent instruction and
data memory interfaces. However, at the system level, both interfaces are
mapped to the same physical [system memory]. This ensures a unified address
space, allowing instructions to be dynamically loaded into the same RAM that
the data path accesses.

Address decoding is handled combinatorially by the shared Wishbone bus, which
routes transactions to the appropriate peripheral based on the requested
address.

[system memory]: https://github.com/GBergatto/via-honoris/blob/main/virtus-rv/rtl/sysmem_wb.sv

**System Memory Map:**

| Peripheral | Base Address | Description |
| --- | --- | --- |
| **BRAM** | `0x8000_0000` | Primary system block RAM (Instructions & Data). |
| **LEDs** | `0x0100_0000` | Memory-mapped I/O for 8 onboard LEDs. |
| **CLINT** | `0x0200_0000` | Core Local Interrupt controller. |
| **SPI** | `0x0300_0000` | SPI Master interface for external peripherals. |
| **Buttons** | `0x0400_0000` | Memory-mapped I/O for 4 onboard pushbuttons. |

### Dual-Port Memory

The system memory (`sysmem_wb`) is instantiated as a dual-port RAM block.
Currently, only Port A is utilized and wired to the shared Wishbone bus. In the
future, Port B could be used to route the instruction master (`imem_wb`)
directly, eliminating bus contention, or to attach a read-only DMA controller
for streaming framebuffer data directly to the screen without CPU intervention.

## Wishbone Bus

The SoC interconnect uses the standard Wishbone bus architecture. Wishbone is
an open-source hardware bus interface designed to allow discrete IP cores to
communicate synchronously. It uses a master/slave topology with a handshake
mechanism (`stb`, `cyc`, `ack`) to coordinate data transfers.

### Instruction and Data Masters

The RISC-V core requires two independent memory interfaces: one to fetch
instructions ([IMEM]) and one to load/store data ([DMEM]). To bridge these to the
SoC interconnect, they are wrapped in dedicated Wishbone Master modules
(`imem_wb` acts as Master 0, and `dmem_wb` acts as Master 1).

[IMEM]: https://github.com/GBergatto/via-honoris/blob/main/virtus-rv/rtl/imem_wb.sv
[DMEM]: https://github.com/GBergatto/via-honoris/blob/main/virtus-rv/rtl/dmem_wb.sv

By definition, a standard shared bus can only be driven by a single master at
any given time. Because the pipelined core operates concurrently, it frequently
attempts to fetch an instruction and access data memory in the exact same clock
cycle. If both masters were wired directly to the system memory, their signals
would collide and corrupt the transaction.

### Arbiter

To resolve these simultaneous bus requests, an active [arbiter] (`arbiter_wb`)
sits between the two masters and the memory map. The arbiter multiplexes the
masters onto the shared bus, granting fixed priority to the Data interface.
This ensures that memory loads and stores are not delayed by instruction
fetches, preventing unnecessary pipeline stalls.

[arbiter]: https://github.com/GBergatto/via-honoris/blob/main/virtus-rv/rtl/arbiter_wb.sv

### Buttons Slave

The [Buttons slave] provides memory-mapped read access to the physical
pushbuttons. The hardware implements a two-stage synchronizer to safely align
the asynchronous physical signals to the system clock and handles logic
inversion, presenting the software with a clean interface where a `1` indicates
the button is pressed, and a `0` indicates it is released.

[Buttons slave]: https://github.com/GBergatto/via-honoris/blob/main/virtus-rv/rtl/buttons_wb.sv

### LED Slave

The [LED slave] allows software to control the board's 8 LEDs via memory-mapped
writes. The hardware automatically inverts the data bits before driving the
physical pins (`leds <= ~s_dat_o[7:0]`). This allows software to treat the LEDs
as active-high (writing `1` turns the LED on) while abstracting away the
physical active-low hardware implementation.

[LED slave]: https://github.com/GBergatto/via-honoris/blob/main/virtus-rv/rtl/hp_soc.sv#L232-L249

### CLINT Slave

The [Core Local Interrupt controller] (CLINT) manages system timing and generates machine
timer interrupts (`mtip`). It implements a 64-bit real-time counter (`mtime`)
that increments on every clock cycle, and a 64-bit comparator (`mtimecmp`). The
hardware timer interrupt (`mtip`) is asserted whenever `mtime >= mtimecmp`.

[Core Local Interrupt controller]: https://github.com/GBergatto/via-honoris/blob/main/virtus-rv/rtl/clint.sv

Because the system Wishbone bus is 32 bits wide, software must access these
64-bit registers as memory-mapped 32-bit high/low word pairs. The module fully
supports Wishbone byte strobes (`wb_sel_i`) for partial register updates.

**CLINT Register Map** (Offsets from Base Address `0x0200_0000`):

- `0x4000`: `mtimecmp` (Lower 32 bits)
- `0x4004`: `mtimecmp` (Upper 32 bits)
- `0xBFF8`: `mtime` (Lower 32 bits)
- `0xBFFC`: `mtime` (Upper 32 bits)

### SPI Controller

The [SPI controller] acts as a bridge between two interfaces: it is a Wishbone
slave to the RISC-V core, but a Master on the external SPI bus. It is
specifically tailored for driving the external TFT screen, providing explicit
memory-mapped control over the Data/Command (`dc`), Chip Select (`cs_n`), and
Reset (`reset_n`) lines alongside the standard clock and MOSI signals.

[SPI controller]: https://github.com/GBergatto/via-honoris/blob/main/virtus-rv/rtl/spi_master_wb.sv

**SPI Register Map** (Offsets from Base Address `0x0300_0000`):

- `0x00` (**Data**): Write-only. Writing 8 or 16 bits here immediately triggers
the transmission.
- `0x04` (**Control**): Read/Write.
    - Bit 0: `dc` (Data/Command pin)
    - Bit 1: `cs_n` (Chip Select pin, active-low)
    - Bit 2: `reset_n` (Hardware Reset pin, active-low)

