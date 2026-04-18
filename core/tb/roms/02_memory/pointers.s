# dmem[1024] = 1028
lui x15, 0x80000
addi x1, x15, 1024
addi x2, x15, 1028
sw   x2, 0(x1)

# dmem[1028] = 42
addi x3, x15, 1028
addi x4, x0, 42
sw   x4, 0(x3)

addi x5, x15, 1024
lw   x6, 0(x5)
lw   x7, 0(x6)

ebreak
