.text
.globl _start

_start:
    # 1. Route traps to our aligned handler
    la t0, trap_handler
    csrw mtvec, t0

    # 2. Initialize our test flags
    li x10, 0           # x10 (a0): Interrupt fired flag
    li x11, 0           # x11 (a1): Final test status

    # 3. Configure the CLINT
    # Read current mtime_lo (Base 0x0200_0000 + 0xBFF8)
    li t1, 0x0200BFF8
    lw t2, 0(t1)
    
    # Add an offset (e.g., 50 cycles) to trigger the interrupt shortly
    addi t2, t2, 50     
    
    # Write to mtimecmp_lo (0x02004000)
    li t3, 0x02004000
    sw t2, 0(t3)
    
    # Write 0 to mtimecmp_hi (0x02004004) assuming we just booted
    sw zero, 4(t3)

    # 4. Arm the Interrupts
    li t0, 0x80         # Bit 7 is MTIE (Machine Timer Interrupt Enable)
    csrs mie, t0
    li t0, 0x8          # Bit 3 is MIE (Global Machine Interrupt Enable)
    csrs mstatus, t0

wait_loop:
    # 5. Spin here until the interrupt handler sets x10 to 1
    beq x10, zero, wait_loop

test_pass:
    # 6. Mark success and halt
    li x11, 0x1337      # Magic success value
    ebreak              # Trigger environment trap to halt simulator

trap_handler:
    # A. Verify it was actually a timer interrupt
    csrr t3, mcause
    li t4, 0x80000007   # MSB set (Interrupt) + code 7 (Timer)
    bne t3, t4, unexpected_trap

    # B. Disable timer interrupts so we don't trap infinitely on the same tick
    li t0, 0x80
    csrc mie, t0

    # C. Set the flag to break the main loop
    li x10, 1

    # D. Return to the instruction that got squashed in the pipeline
    mret

unexpected_trap:
    li x11, 0xDEAD      # Magic failure value
    ebreak

