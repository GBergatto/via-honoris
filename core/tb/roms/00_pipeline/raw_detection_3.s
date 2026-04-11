# RAW between 1st and 5th instr -> no stall
addi x1, x0, 1
addi x3, x0, 7
addi x3, x0, 8
addi x3, x0, 9
addi x2, x1, 2

ebreak
