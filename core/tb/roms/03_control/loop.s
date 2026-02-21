main:
   addi x1, x0, 5       # Counter = 5
   addi x2, x0, 0       # Accumulator = 0
   addi x3, x0, 10      # Constant 10

loop:
   # Body of loop
   add  x2, x2, x3      # x2 += 10
   addi x1, x1, -1      # Decrement counter

   # Branch back if x1 != 0
   # This generates a Control Hazard every single time it is taken!
   bne  x1, x0, loop

end:
   # We arrive here when x1 == 0
   addi x4, x0, 0xF     # Marker that we finished
   ebreak
