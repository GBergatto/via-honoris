# Base address
lui x1, 0
# Prepare data
addi x2, x0, 0x12   # byte 0 (little endian) -> 0x12
addi x3, x0, 0x34   # byte 1 -> 0x34
addi x4, x0, 0x56   # byte 2 -> 0x56
addi x5, x0, 0x78   # byte 3 -> 0x78

# Store bytes
sb x2, 0(x1)
sb x3, 1(x1)
sb x4, 2(x1)
sb x5, 3(x1)

# Now memory at 0 contains 0x78563412. Let's load it as word:
lw x6, 0(x1)        # x6 = 0x78563412

# Store halfwords
lui x2, 0
addi x2, x2, 0x10B  # 0x010B
addi x3, x0, 0x10D  # 0x010D
sh x2, 4(x1)        # stores 0x010B at mem[4]
sh x3, 6(x1)        # stores 0x010D at mem[6]

# Now memory at 4 contains 0x010D010B
lw x7, 4(x1)        # x7 = 0x010D010B

# Load unsigned bytes/halfwords
lbu x8, 0(x1)       # x8 = 0x12
lhu x9, 4(x1)       # x9 = 0x010B

# Load signed bytes/halfwords with sign extension
addi x10, x0, -1
sb x10, 8(x1)       # mem[8] = 0xFF
lb x11, 8(x1)       # x11 = 0xFFFFFFFF
lbu x12, 8(x1)      # x12 = 0x000000FF

# Halfword sign extension
addi x10, x0, -1
sh x10, 10(x1)      # mem[10] = 0xFFFF
lh x13, 10(x1)      # x13 = 0xFFFFFFFF
lhu x14, 10(x1)     # x14 = 0x0000FFFF
