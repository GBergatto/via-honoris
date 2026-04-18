/* verilator lint_off IMPORTSTAR */
import core_types_pkg::*;

module hp_core (
   input  logic clk,
   input  logic rst,
   input  logic ext_stall, // stall from external bus
   output logic core_stall,

   /* Instruction memory interface */
   output logic [31:0] imem_addr,
   input  logic [31:0] imem_data,

   /* Data memory interface */
   output logic [31:0] dmem_addr,
   output logic [31:0] dmem_wdata,
   input  logic [31:0] dmem_rdata,
   output logic        dmem_re,
   output logic [3:0]  dmem_we
);

/* Control Signals Structs */
typedef struct packed {
   alu_op_t alu_op;
   op1_src_e op1_src;
   logic op2_src;
   logic reg_write;
   logic mem_write;
   logic mem_read;
   logic [1:0] result_src;
   logic [2:0] funct3;
   mem_size_e mem_size;
   logic mem_unsigned;
   logic branch;
   logic jump;
   logic jump_reg;
} ctrl_t;

typedef struct packed {
   logic mem_read;
   logic mem_write;
   logic reg_write;
   logic [1:0] result_src;
   mem_size_e mem_size;
   logic mem_unsigned;
} ctrl_M_t;

typedef struct packed {
    logic reg_write;
    logic [1:0] result_src;
    mem_size_e mem_size;
    logic mem_unsigned;
} ctrl_W_t;

ctrl_t ctrl_D, ctrl_E;
ctrl_M_t ctrl_M;
ctrl_W_t ctrl_W;

// ===================================================================================
// Fetch Stage
// ===================================================================================
logic stall, pc_src_E, pc_src_W;
logic [31:0] pc_F, pc_next, pc_plus4_F, pc_target_E;
logic [31:0] pc_target_W;

assign imem_addr = pc_F; // Drive the external instruction memory

assign pc_plus4_F = pc_F + 4;
assign pc_next = (pc_src_W) ? pc_target_W : // traps
                ((pc_src_E) ? pc_target_E : // branches/jumps
                              pc_plus4_F);  // next sequential PC

/* Program Counter */
always_ff @(posedge clk or posedge rst) begin
   if (rst)
      pc_F <= RESET_PC;
   else if (!stall && !ext_stall)
      pc_F <= pc_next;
end

// ===================================================================================
// Decode Stage
// ===================================================================================
logic [31:0] pc_D, pc_plus4_D;
logic [31:0] inst_D;
logic flush_D;

/* IF/ID pipeline registers */
always_ff @(posedge clk or posedge rst) begin
   if (rst) begin
      flush_D <= 1'b0;
   end else if (!ext_stall) begin
      // Record if a branch was taken so we can flush the incoming instruction next cycle
      flush_D <= pc_src_E || pc_src_W;
   end
end

always_ff @(posedge clk) begin
   if (!ext_stall) begin
      if (!stall) begin
         pc_D <= pc_F;
         pc_plus4_D <= pc_F + 4;
      end
   end
end

/* Instruction Flush Mux */
// Flush the instruction after a jump
assign inst_D = (flush_D) ? 32'h00000000 : imem_data;

/* Immediate Generator */
logic [31:0] imm_D;
immgen immgen_i (
   .inst (inst_D),
   .imm (imm_D)
);

/* Decoder */
logic [6:0] opcode;
logic [4:0] rd_D;
logic [4:0] rs1_D;
logic [4:0] rs2_D;
logic [6:0] funct7;

always_comb begin
   opcode        = inst_D[6:0];
   rd_D          = inst_D[11:7];
   ctrl_D.funct3 = inst_D[14:12];
   rs1_D         = inst_D[19:15];
   rs2_D         = inst_D[24:20];
   funct7        = inst_D[31:25];
end

logic [31:0] write_data_E, rs1_fwd, op1, op2, alu_out_M;
logic is_env_trap_D, is_mret_D, is_csr_D;
csr_addr_e csr_addr_D;

assign csr_addr_D = csr_addr_e'(inst_D[31:20]);
assign is_csr_D = (opcode == OPC_SYSTEM) && (ctrl_D.funct3 != 3'b000);
assign is_env_trap_D = (opcode == OPC_SYSTEM) && (ctrl_D.funct3 == 3'b000) && (csr_addr_D[11:1] == 11'b0);
assign is_mret_D = (opcode == OPC_SYSTEM) && (ctrl_D.funct3 == 3'b000) && (csr_addr_D == 12'h302);

/* Control Logic */
control control_i (
   .opcode (opcode),
   .funct3 (ctrl_D.funct3),
   .funct7 (funct7),
   .op1_src (ctrl_D.op1_src),
   .op2_src (ctrl_D.op2_src),
   .reg_write (ctrl_D.reg_write),
   .mem_read (ctrl_D.mem_read),
   .mem_write (ctrl_D.mem_write),
   .mem_size (ctrl_D.mem_size),
   .mem_unsigned (ctrl_D.mem_unsigned),
   .result_src (ctrl_D.result_src),
   .branch (ctrl_D.branch),
   .jump (ctrl_D.jump),
   .jump_reg (ctrl_D.jump_reg)
);

/* ALU Control Logic */
alu_control alu_control_i (
   .opcode (opcode),
   .funct3 (ctrl_D.funct3),
   .funct7 (funct7),
   .alu_op (ctrl_D.alu_op)
);

logic [4:0] rd_W;

/* Register File */
logic [31:0] rs1_data_D, rs2_data_D, result_W;
regfile regfile_i (
   .clk (clk),
   .rs1 (rs1_D),
   .rs2 (rs2_D),
   .rd (rd_W),
   .rd_data (result_W),
   .write (ctrl_W.reg_write),
   .rs1_data (rs1_data_D),
   .rs2_data (rs2_data_D)
);

csr_addr_e csr_addr_W /* verilator public */;
logic [31:0] trap_cause_W;
assign trap_cause_W = (csr_addr_W == 12'h001)
                        ? 32'd3   // EBREAK -> breakpoint
                        : 32'd11; // M-mode

logic [31:0] pc_W;
logic [31:0] csr_read_data_D, csr_write_data_W;
logic is_mret_W, is_csr_W;
logic is_env_trap_W /* verilator public */;

/* CSR File */
logic [31:0] mtvec_out, mepc_out;
csr_file csr_file_i (
   .clk (clk),
   .rst (rst),
   .read_addr (csr_addr_D),
   .read_data (csr_read_data_D),
   .write_enable (is_csr_W),
   .write_addr (csr_addr_W),
   .write_data (csr_write_data_W),
   .trap (is_env_trap_W),
   .trap_pc (pc_W),
   .trap_cause (trap_cause_W),
   .mret (is_mret_W),
   .mtvec_out (mtvec_out),
   .mepc_out (mepc_out)
);

// ===================================================================================
// Execute Stage
// ===================================================================================
logic [31:0] rs1_data_E, rs2_data_E, imm_E;
logic [31:0] pc_E, pc_plus4_E;
logic [31:0] csr_read_data_E, csr_write_data_E;
logic [4:0] rd_E, rd_M, rs1_E, rs2_E;
logic is_env_trap_E, is_mret_E, is_csr_E;
csr_addr_e csr_addr_E;

/* ID/EX pipeline registers */
always_ff @(posedge clk or posedge rst) begin
   if (rst) begin
      ctrl_E <= '0;
      is_env_trap_E <= 1'b0;
      is_mret_E <= 1'b0;
      is_csr_E <= 1'b0;
   end else if (!ext_stall) begin
      if (pc_src_E || pc_src_W || stall) begin
         // inject bubble in the EX stage, i.e. do nothing for one cycle
         ctrl_E <= '0;
         is_env_trap_E <= 1'b0;
         is_mret_E <= 1'b0;
         is_csr_E <= 1'b0;

      end else begin
         ctrl_E <= ctrl_D;
         rs1_data_E <= rs1_data_D;
         rs2_data_E <= rs2_data_D;
         imm_E <= imm_D;
         rs1_E <= rs1_D;
         rs2_E <= rs2_D;
         rd_E <= rd_D;
         pc_E <= pc_D;
         pc_plus4_E <= pc_plus4_D;
         csr_addr_E <= csr_addr_D;
         is_env_trap_E <= is_env_trap_D;
         is_mret_E <= is_mret_D;
         is_csr_E <= is_csr_D;
         csr_read_data_E <= csr_read_data_D;
      end
   end
end

/* Hazard Detection */
logic [1:0] forward_a_E, forward_b_E;
// Stall only if the instruction in D reads the output of a load in E
assign stall = ctrl_E.mem_read && (rd_E == rs1_D || rd_E == rs2_D);
assign core_stall = stall;

// Forwarding for source op1
always_comb begin
   if (rd_M != 0 && rs1_E == rd_M && ctrl_M.reg_write) begin
      forward_a_E = 2'b10; // Forward from MEM
   end else if (rd_W != 0 && rs1_E == rd_W && ctrl_W.reg_write) begin
      forward_a_E = 2'b01; // Forward from WB
   end else begin
      forward_a_E = 2'b00; // No Forwarding
   end
end

// Forwarding for source B
always_comb begin
   if (rd_M != 0 && rs2_E == rd_M && ctrl_M.reg_write) begin
      forward_b_E = 2'b10; // Forward from MEM
   end else if (rd_W != 0 && rs2_E == rd_W && ctrl_W.reg_write) begin
      forward_b_E = 2'b01; // Forward from WB
   end else begin
      forward_b_E = 2'b00; // No Forwarding
   end
end

logic [31:0] csr_read_data_M;
logic is_csr_M;

/* Forwarding Multiplexers */
always_comb begin
    case (forward_a_E)
        2'b00: rs1_fwd = rs1_data_E; // No forwarding
        2'b01: rs1_fwd = result_W;   // Forwarded from Writeback stage
        2'b10: rs1_fwd = (is_csr_M) ? csr_read_data_M : alu_out_M;  // Forwarded from Memory stage
        default: rs1_fwd = rs1_data_E;
    endcase

    case (forward_b_E)
        2'b00: write_data_E = rs2_data_E; // No forwarding
        2'b01: write_data_E = result_W;   // Forwarded from Writeback stage
        2'b10: write_data_E = (is_csr_M) ? csr_read_data_M : alu_out_M;  // Forwarded from Memory stage
        default: write_data_E = rs2_data_E;
    endcase
end

/* CSR write data calculation in EX */
always_comb begin
   unique case (ctrl_E.funct3)
      3'b001: csr_write_data_E = rs1_fwd;
      3'b010: csr_write_data_E = csr_read_data_E | rs1_fwd;
      3'b011: csr_write_data_E = csr_read_data_E & ~rs1_fwd;
      3'b101: csr_write_data_E = {27'b0, rs1_E};
      3'b110: csr_write_data_E = csr_read_data_E | {27'b0, rs1_E};
      3'b111: csr_write_data_E = csr_read_data_E & ~{27'b0, rs1_E};
      default: csr_write_data_E = 32'b0;
   endcase
end

/* PC Target */
assign pc_target_E = ((ctrl_E.jump_reg) ? rs1_fwd : pc_E) + imm_E;

/* ALU sources multiplexers */
always_comb begin
   case (ctrl_E.op1_src)
      OP1_ZERO: op1 = 32'b0;
      OP1_PC:   op1 = pc_E;
      default:  op1 = rs1_fwd;
   endcase

   op2 = (ctrl_E.op2_src) ? imm_E : write_data_E;
end

logic [31:0] alu_out_D;
logic branch_condition_E, zero_E, lt_E, ltu_E;

/* ALU */
alu alu_i (
   .op1 (op1),
   .op2 (op2),
   .alu_op (ctrl_E.alu_op),
   .out (alu_out_D),
   .zero (zero_E),
   .lt (lt_E),
   .ltu (ltu_E)
);

/* Branching logic */
always_comb begin
    case (ctrl_E.funct3)
        3'b000: branch_condition_E = zero_E;  // BEQ
        3'b001: branch_condition_E = !zero_E; // BNE
        3'b100: branch_condition_E = lt_E;    // BLT
        3'b101: branch_condition_E = !lt_E;   // BGE
        3'b110: branch_condition_E = ltu_E;   // BLTU
        3'b111: branch_condition_E = !ltu_E;  // BGEU
        default: branch_condition_E = 1'b0;
    endcase
end

assign pc_src_E = ctrl_E.jump || (ctrl_E.branch && branch_condition_E);

// ===================================================================================
// Memory Stage
// ===================================================================================
logic [31:0] pc_M, pc_plus4_M, write_data_M;
logic [31:0] csr_write_data_M;
logic is_env_trap_M, is_mret_M;
csr_addr_e csr_addr_M;

/* EX/MEM pipeline registers */
always_ff @(posedge clk or posedge rst) begin
   if (rst) begin
      ctrl_M <= '0;
      is_csr_M <= 1'b0;
      is_env_trap_M <= 1'b0;
      is_mret_M <= 1'b0;
   end else if (!ext_stall) begin
      if (pc_src_W) begin
         // flush MEM stage when a trap resolves in WB
         ctrl_M <= '0;
         is_csr_M <= 1'b0;
         is_env_trap_M <= 1'b0;
         is_mret_M <= 1'b0;
      end else begin
         ctrl_M.reg_write <= ctrl_E.reg_write;
         ctrl_M.mem_read  <= ctrl_E.mem_read;
         ctrl_M.mem_write <= ctrl_E.mem_write;
         ctrl_M.result_src <= ctrl_E.result_src;
         ctrl_M.mem_size <= ctrl_E.mem_size;
         ctrl_M.mem_unsigned <= ctrl_E.mem_unsigned;

         is_csr_M <= is_csr_E;
         is_env_trap_M <= is_env_trap_E;
         is_mret_M <= is_mret_E;
      end
   end
end

always_ff @(posedge clk) begin
   if (!ext_stall && !pc_src_W) begin
      alu_out_M <= alu_out_D;
      write_data_M <= write_data_E;
      rd_M <= rd_E;
      pc_M <= pc_E;
      pc_plus4_M <= pc_plus4_E;
      csr_read_data_M <= csr_read_data_E;
      csr_write_data_M <= csr_write_data_E;
      csr_addr_M <= csr_addr_E;
   end
end

logic [3:0] dmem_we_M;
logic [31:0] write_data_aligned_M;

/* Store masking and data alignment */
always_comb begin
   if (ctrl_M.mem_write) begin
      case (ctrl_M.mem_size)
         MEM_SIZE_B: dmem_we_M = 4'b0001 << alu_out_M[1:0];       // SB
         MEM_SIZE_H: dmem_we_M = 4'b0011 << {alu_out_M[1], 1'b0}; // SH
         MEM_SIZE_W: dmem_we_M = 4'b1111;                         // SW
         default: dmem_we_M = 4'b0000;
      endcase
   end else begin
      dmem_we_M = 4'b0000;
   end

   case (ctrl_M.mem_size)
      MEM_SIZE_B: write_data_aligned_M = {4{write_data_M[7:0]}};  // SB
      MEM_SIZE_H: write_data_aligned_M = {2{write_data_M[15:0]}}; // SH
      default: write_data_aligned_M = write_data_M;               // SW
   endcase
end

/* Drive External Data Memory */
assign dmem_addr  = alu_out_M;
assign dmem_wdata = write_data_aligned_M;
assign dmem_we    = dmem_we_M;
assign dmem_re    = ctrl_M.mem_read;

// ===================================================================================
// Writeback Stage
// ===================================================================================
logic [31:0] pc_plus4_W, alu_out_W, mem_out_W, csr_read_data_W;

/* MEM/WB pipeline registers */
always_ff @(posedge clk or posedge rst) begin
   if (rst) begin
      ctrl_W <= '0;
      is_csr_W <= 1'b0;
      is_env_trap_W <= 1'b0;
      is_mret_W <= 1'b0;
   end else if (!ext_stall) begin
      ctrl_W.reg_write <= ctrl_M.reg_write;
      ctrl_W.result_src <= ctrl_M.result_src;
      ctrl_W.mem_size <= ctrl_M.mem_size;
      ctrl_W.mem_unsigned <= ctrl_M.mem_unsigned;
      is_csr_W <= is_csr_M;
      is_env_trap_W <= is_env_trap_M;
      is_mret_W <= is_mret_M;
   end
end

always_ff @(posedge clk) begin
   if (!ext_stall) begin
      alu_out_W <= alu_out_M;
      rd_W <= rd_M;
      pc_plus4_W <= pc_plus4_M;
      csr_read_data_W <= csr_read_data_M;
      csr_write_data_W <= csr_write_data_M;
      csr_addr_W <= csr_addr_M;
      pc_W <= pc_M;
   end
end


/* PC Target W for traps */
assign pc_src_W = is_env_trap_W || is_mret_W;
assign pc_target_W = (is_mret_W) ? mepc_out : ((mtvec_out[1:0] == 2'b01) ? {mtvec_out[31:2], 2'b00} : mtvec_out);

/* Read Data Memory */
logic [7:0] byte_data;
logic [15:0] half_data;

/* Load masking and data alignment */
always_comb begin
   byte_data = 8'(dmem_rdata >> {alu_out_W[1:0], 3'b000});
   half_data = 16'(dmem_rdata >> {alu_out_W[1], 4'b0000});

   if (ctrl_W.mem_unsigned) begin
      case (ctrl_W.mem_size)
         MEM_SIZE_B: mem_out_W = {24'b0, byte_data}; // LBU
         MEM_SIZE_H: mem_out_W = {16'b0, half_data}; // LHU
         default: mem_out_W = dmem_rdata;            // LW
      endcase
   end else begin
      case (ctrl_W.mem_size)
         MEM_SIZE_B: mem_out_W = {{24{byte_data[7]}}, byte_data};  // LB
         MEM_SIZE_H: mem_out_W = {{16{half_data[15]}}, half_data}; // LH
         default: mem_out_W = dmem_rdata;                          // LW
      endcase
   end
end

/* ResultW Multiplexer */
always_comb begin
  if (is_csr_W) begin
      result_W = csr_read_data_W;
   end else begin
      case (ctrl_W.result_src)
         2'b00: result_W = alu_out_W;
         2'b01: result_W = mem_out_W;
         2'b10: result_W = pc_plus4_W;
         default: result_W = 0;
      endcase
   end
end

endmodule
