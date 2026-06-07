# Trap Handling

In RISC-V nomenclature, **trap** is the umbrella term for any synchronous or
asynchronous event that causes the hardware to transfer control to a trap
handler. Traps are categorized into two types:

- **Exceptions**: Synchronous events triggered by the execution of a specific
instruction, such as environment calls (`ecall`) or breakpoints (`ebreak`).
- **Interrupts**: Asynchronous events triggered by external hardware signals,
such as the machine timer interrupt (`mtip`), occurring independently of the
current instruction stream.

Note that the current microarchitecture does not handle exceptions triggered by
illegal instructions (e.g., unknown opcodes or invalid CSR accesses),
Instruction Address Misaligned fetches, or Load/Store Address Misaligned data
accesses.

## Decoding

To maintain precise exceptions, traps and privileged instructions are
identified early in the Decode stage, but are pipelined down to the Writeback
stage before they trigger any architectural state changes. The core relies on
the following internal control signals to decode these events:

- `is_sync_exception`: Identifies environment calls (`ecall`) and breakpoints
(`ebreak`).
- `is_interrupt`: Asserted when an asynchronous interrupt (`irq_pending`) is
detected and no prior interrupts are currently traversing the Execute, Memory,
or Writeback stages.
- `is_mret`: Detects the Machine-mode return (`mret`) instruction.
- `is_csr`: Asserted for standard CSR atomic instructions (e.g., `csrrw`,
`csrrs`), distinguishing functional register accesses from context-switching
traps.

## Context switching

Once decoded, these control signals dictate how the pipeline handles the trap,
with a different mechanism depending on its type. Synchronous exceptions like
`ecall` and `ebreak` (`is_sync_exception_D`), as well as CSR operations
(`is_csr_D`), are part of the normal instruction stream. They flow naturally
down the pipeline registers until reaching the Writeback stage, where they
update the architectural state.

On the other hand, because asynchronous interrupts (`is_interrupt_D`) originate
externally, the core must handle them without violating pipeline commit order.
To allow older instructions in the Execute and Memory stages to safely retire,
the hardware does not halt immediately. Instead, it replaces the interrupted
instruction in the Decode stage with a pipeline bubble. The address of this
interrupted instruction is preserved and passed down the pipeline so it can be
saved to the `mepc` register in the Writeback stage.

When a trap or return instruction finally reaches the Writeback stage
(`is_interrupt_W`, `is_sync_exception_W`, or `is_mret_W`), the core resolves
the control flow, flushes the trailing instructions in the early pipeline
stages, and performs the context switch. The [CSR file] facilitates this by
capturing the address of the interrupted instruction into `mepc` and recording
the exception or interrupt code into `mcause` for the software handler to read.

Simultaneously, the Program Counter is redirected by [this multiplexer]. For a
`mret` instruction, the PC jumps back to the address stored in `mepc`. If the
trap is an interrupt and `mtvec` is configured in Vectored mode, the core
applies a specific offset to the base address. For all synchronous exceptions
or for interrupts in Direct mode, the PC is set jumps directly to the base address.

[CSR file]: https://github.com/GBergatto/via-honoris/blob/main/virtus-rv/rtl/csr_file.sv
[this multiplexer]: https://github.com/GBergatto/via-honoris/blob/main/virtus-rv/rtl/virtus_core.sv#L515-L518

## State management

To prevent unintended nested interrupts during handler execution, the hardware
automatically updates the interrupt enable stack within `mstatus`. The current
Machine Interrupt Enable (`MIE`, bit 3) is saved into the Machine Previous
Interrupt Enable (`MPIE`, bit 7), and `MIE` is cleared to zero.

Executing an `mret` instruction reverses this process: it restores the previous
interrupt state by copying `MPIE` back into `MIE`, sets `MPIE` to `1`, and
resumes execution by redirecting the Program Counter to the address held in
`mepc`.

## Interrupt requests

The [CSR file] manages incoming asynchronous requests, with the machine timer
interrupt (`mtip`) currently being the only supported source. An external
trigger on this pin is only propagated to the core as `irq_pending` if it
passes two levels of masking:

1. **Global Enable**: The `MIE` (bit 3) bit in the `mstatus` register.
2. **Source Enable**: The correspon]ding bit in the `mie` register.
