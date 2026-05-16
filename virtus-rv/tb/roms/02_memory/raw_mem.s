lui x1, 0x80000
addi x1, x1, 1024  # Address
addi x2, x0, 100 # Data A
addi x3, x0, 200 # Data B

sw   x2, 0(x1) # dmem[64]
lw   x4, 0(x1) # x4 = dmem[64]

sw   x3, 0(x1) # dmem[64] = 200
lw   x5, 0(x1) # x5 = dmem[64]

add  x6, x4, x5 # x6 = 100 + 200 = 300

ebreak
