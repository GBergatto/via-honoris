lui x1, 0x80000
addi x1, x1, 1024
addi x2, x0, 0xAA
addi x3, x0, 0xBB

sw   x2, 4(x1) # store 0xAA at address 104
sw   x3, 8(x1) # store 0xBB at address 108

lw   x4, 4(x1) # Load 0xAA from 104
lw   x5, 8(x1) # Load 0xBB from 108
lw   x6, 0(x1) # Load from 100 (should be 0, assuming clean memory)

ebreak
