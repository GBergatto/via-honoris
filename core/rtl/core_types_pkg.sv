package core_types_pkg;

   /* verilator lint_off UNUSEDPARAM */
   parameter logic [31:0] RESET_PC = 32'h8000_0000;
   /* verilator lint_on UNUSEDPARAM */

   /* Enum for instruction opcodes */
   typedef enum logic [6:0] {
      OPC_LOAD     = 7'b0000011, // Load
      OPC_MISC_MEM = 7'b0001111, // Fence
      OPC_OP_IMM   = 7'b0010011, // I-type
      OPC_AUIPC    = 7'b0010111, // AUIPC
      OPC_STORE    = 7'b0100011, // Store
      OPC_OP       = 7'b0110011, // R-type
      OPC_LUI      = 7'b0110111, // LUI
      OPC_BRANCH   = 7'b1100011, // B-type
      OPC_JALR     = 7'b1100111, // JALR
      OPC_JAL      = 7'b1101111, // JAL
      OPC_SYSTEM   = 7'b1110011  // ecall, ebreak, CSRs
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

   /* Enum for CSR addresses */
   typedef enum logic [11:0] {
      CSR_FCSR      = 12'h003,
      CSR_VCSR      = 12'h00F,
      CSR_SATP      = 12'h180,
      CSR_STVEC     = 12'h105,
      CSR_MSTATUS   = 12'h300,
      CSR_MEDELEG   = 12'h302,
      CSR_MIDELEG   = 12'h303,
      CSR_MIE       = 12'h304,
      CSR_MTVEC     = 12'h305,
      CSR_MSCRATCH  = 12'h340,
      CSR_MEPC      = 12'h341,
      CSR_MCAUSE    = 12'h342,
      CSR_MIP       = 12'h344,
      CSR_PMPCFG0   = 12'h3A0,
      CSR_PMPADDR0  = 12'h3B0,
      CSR_MNSTATUS  = 12'h744,
      CSR_MHARTID   = 12'hF14
   } csr_addr_e;

endpackage
