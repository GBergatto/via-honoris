lui x15, 0x80000
addi x1, x0, 0x111
sw   x1, 1024(x15)

addi x2, x0, 0x222
sw   x2, 1028(x15)

lw   x3, 1024(x15)
lw   x4, 1028(x15)
add  x5, x4, x0

ebreak
