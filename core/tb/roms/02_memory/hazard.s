# dmem[1024] = 10
lui x1, 0x80000
addi x1, x1, 1024
addi x5, x0, 10
sw   x5, 0(x1)

lw   x2, 0(x1)
add  x3, x2, x2
add  x4, x3, x2

ebreak
