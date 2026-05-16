.section .text.init
.globl _start

_start:
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop

    # Initialize stack pointer from linker script
    la sp, _estack
    
    # Clear the BSS section
    la t0, _sbss
    la t1, _ebss
    bgeu t0, t1, 2f 
1:
    sw zero, 0(t0)
    addi t0, t0, 4
    bltu t0, t1, 1b
2:

    # Call main
    jal ra, main

    # Loop forever if main returns
inf_loop:  j inf_loop
