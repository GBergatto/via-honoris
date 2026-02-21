main:
    addi x1, x0, 10
    addi x2, x0, 10
    addi x3, x0, 20

    # Test 1: BEQ (Should Take)
    # 10 == 10, so we jump to 'match'. 
    # If this fails, x4 becomes 0xAD.
    beq  x1, x2, match
    addi x4, x0, 0xAD
    jal  x0, fail

match:
    addi x4, x0, 1        # x4 = 1 (Success)

    # Test 2: BNE (Should NOT Take)
    # 10 == 10, so condition is false. Should NOT jump.
    # If this fails (jumps), x5 remains 0.
    bne  x1, x2, fail_bne
    addi x5, x0, 1        # x5 = 1 (Success)
    jal  x0, test_blt

fail_bne:
    addi x5, x0, 0xAD
    jal  x0, fail

test_blt:
    # Test 3: BLT (Should Take)
    # 10 < 20, so we jump.
    blt  x1, x3, success_blt
    addi x6, x0, 0xAD
    jal  x0, fail

success_blt:
    addi x6, x0, 1        # x6 = 1 (Success)
    ebreak

fail:
    ebreak
