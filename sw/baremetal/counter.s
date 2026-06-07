# 8-bit counter on the onboard LEDs

.section .text
    .globl _start

_start:
    # Build address 0x0100_0000
    addi x1, x0, 1
    slli x1, x1, 24

    # Initialize fast counter
    addi x2, x0, 0

main_loop:
    # Increment the fast counter
    addi x2, x2, 1

    # Extract slow-moving upper bits
    srli x4, x2, 18 # <- decrease shift amount to speed up clock

    # Write the slow-moving bits to the LEDs
    sw x4, 0(x1)

    # Loop forever
    jal x0, main_loop
