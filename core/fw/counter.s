.section .text
    .globl _start

_start:
    # 1. Build address 0x0100_0000 in x1
    addi x1, x0, 1
    slli x1, x1, 24
    
    # 2. Initialize our massive counter in x2
    addi x2, x0, 0

main_loop:
    # 3. Increment the massive counter by 1
    addi x2, x2, 1
    
    # 4. Shift it right by 18 bits into x4
    # (This takes the slow-moving upper bits and moves them to the bottom 8 bits)
    srli x4, x2, 18
    
    # 5. Write the slow-moving bits to the LEDs
    sw x4, 0(x1)
    
    # 6. Loop forever
    jal x0, main_loop
