# Test LUI
lui x1, 0x12345    # x1 = 0x12345000
lui x2, 0xFFFFF    # x2 = 0xFFFFF000

# Test AUIPC
# pc here is 0x00000008
auipc x3, 0x1000   # x3 = 0x00000008 + 0x01000000 = 0x01000008
# pc here is 0x0000000c
auipc x4, 0x0      # x4 = 0x0000000c


ebreak
