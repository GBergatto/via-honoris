package core_types_pkg;

   typedef enum logic [6:0] {
      OPC_LOAD   = 7'b0000011, // Load
      OPC_OP_IMM = 7'b0010011, // I-type
      OPC_AUIPC  = 7'b0010111, // AUIPC
      OPC_STORE  = 7'b0100011, // Store
      OPC_OP     = 7'b0110011, // R-type
      OPC_LUI    = 7'b0110111, // LUI
      OPC_BRANCH = 7'b1100011, // B-type
      OPC_JALR   = 7'b1100111, // JALR
      OPC_JAL    = 7'b1101111, // JAL
      OPC_SYSTEM = 7'b1110011  // ecall, ebreak, CSRs
   } opcode_e;

   // Ordered following the R-type instructions in Table from Chapter 35
   typedef enum logic [3:0] {
      ALU_ADD,
      ALU_SUB,
      ALU_SLL,
      ALU_SLT,
      ALU_SLTU,
      ALU_XOR,
      ALU_SRL,
      ALU_SRA,
      ALU_OR,
      ALU_AND
  } alu_op_t;

endpackage
