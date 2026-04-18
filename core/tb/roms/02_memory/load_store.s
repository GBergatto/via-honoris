lui x1, 0x80000
addi x1, x1, 1024
addi x2, x0, 42
sw   x2, 0(x1)
lw   x3, 0(x1)
addi x4, x3, 1

ebreak
