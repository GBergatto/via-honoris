main:
   addi x10, x0, 5      # Argument = 5
    
   # CALL: Jump to 'func', save return address in x1
   # PC is 0x04 here. x1 should become 0x08.
   jal  x1, func

   # RETURN POINT: execution resumes here after 'ret'
   addi x11, x10, 1     # x11 = 15 + 1 = 16
   jal x0, end

func:
   # Function: Add 10 to argument
   addi x10, x10, 10    # x10 = 15

   # RETURN: Jump to address in x1 (JALR)
   jalr x0, 0(x1)
   ebreak

end:
   ebreak
