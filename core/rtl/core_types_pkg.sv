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

   parameter logic [31:0] RESET_PC = 32'h8000_0000;
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

   /* Enum for ALU op1 multiplexer */
   typedef enum logic [1:0] {
      OP1_RS1  = 2'b00,
      OP1_ZERO = 2'b01,
      OP1_PC   = 2'b10
   } op1_src_e;

   /* Enum for load/store size */
   typedef enum logic [1:0] {
      MEM_SIZE_B = 2'b00,
      MEM_SIZE_H = 2'b01,
      MEM_SIZE_W = 2'b10
   } mem_size_e;

endpackage
