# Comprehensive Data Hazard Test
# Targets: Forwarding (EX/MEM), Stalling (Load-Use), Store-Bypass

 # ---------------------------------------------------------
 # 1. Setup Base Registers
 # ---------------------------------------------------------
 addi x1, x0, 10      # x1 = 10

 # ---------------------------------------------------------
 # 2. RAW Hazard: EX Stage Forwarding
 # The second ADD needs x2 while the first ADD is still in MEM
 # ---------------------------------------------------------
 add  x2, x1, x1      # x2 = 10 + 10 = 20
 add  x3, x2, x2      # x3 = 20 + 20 = 40 (Hazard: x2 from EX)

 # ---------------------------------------------------------
 # 3. RAW Hazard: MEM Stage Forwarding
 # The ADD needs x4, which is currently in WB (or end of MEM)
 # ---------------------------------------------------------
 addi x4, x0, 100     # x4 = 100
 nop                  # Gap
 add  x5, x4, x4      # x5 = 100 + 100 = 200 (Hazard: x4 from MEM/WB)

 # ---------------------------------------------------------
 # 4. Store Data Forwarding (The "SW Bug" Test)
 # We calc x6 and immediately store it. If forwarding fails,
 # memory gets the old value of x6 (0 or garbage).
 # ---------------------------------------------------------
 addi x6, x0, 55      # x6 = 55
 sw   x6, 0(x0)       # Mem[0] = 55. (Needs forwarding from EX to Store Data)

 # ---------------------------------------------------------
 # 5. Load-Use Hazard (The "Stall" Test)
 # The ADD uses x7 immediately. The CPU *must* stall 1 cycle.
 # ---------------------------------------------------------
 lw   x7, 0(x0)       # Load 55 from address 0 into x7
 add  x8, x7, x1      # x8 = 55 + 10 = 65 (Stall + Forward form WB)

 # ---------------------------------------------------------
 # 6. Load-Store Hazard
 # Load x9, then store it. Requires stall or WB-forwarding.
 # ---------------------------------------------------------
 lw   x9, 0(x0)       # x9 = 55
 sw   x9, 4(x0)       # Mem[4] = 55.

 # ---------------------------------------------------------
 # 7. Verification Read
 # Read back the value we just stored at 4 to ensure SW worked
 # ---------------------------------------------------------
 lw   x10, 4(x0)      # x10 = 55

