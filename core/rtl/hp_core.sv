/* verilator lint_off IMPORTSTAR */
import core_types_pkg::*;

module hp_core (
   input  logic clk,
   input  logic rst,
   output logic core_stall,

   /* Instruction memory interface */
   output logic [31:0] imem_addr,
   input  logic [31:0] imem_data,

   /* Data memory interface */
   output logic [31:0] dmem_addr,
   output logic [31:0] dmem_wdata,
   input  logic [31:0] dmem_rdata,
   output logic        dmem_re,
   output logic        dmem_we
);

/* Control Signals Structs */
typedef struct packed {
   alu_op_t alu_op;
   logic alu_src;
   logic reg_write;
   logic mem_write;
   logic mem_read;
   logic [1:0] result_src;
   logic [2:0] funct3;
   logic branch;
   logic jump;
   logic jump_reg;
} ctrl_t;

typedef struct packed {
   logic mem_read;
   logic mem_write;
   logic reg_write;
   logic [1:0] result_src;
} ctrl_M_t;

typedef struct packed {
    logic reg_write;
    logic [1:0] result_src;
} ctrl_W_t;

ctrl_t ctrl_D, ctrl_E;
ctrl_M_t ctrl_M;
ctrl_W_t ctrl_W;

// ===================================================================================
// Fetch Stage
// ===================================================================================
logic stall, pc_src_E;
logic [31:0] pc_F, pc_next, pc_plus4_F, pc_target_E;

assign imem_addr = pc_F; // Drive the external instruction memory

assign pc_plus4_F = pc_F + 4;
assign pc_next = (pc_src_E) ? pc_target_E : pc_plus4_F;

/* Program Counter */
always_ff @(posedge clk or posedge rst) begin
   if (rst)
      pc_F <= 32'h0;
   else if (!stall)
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
      pc_D <= 32'b0;
      pc_plus4_D <= 32'b0;
      flush_D <= 1'b0;
   end else begin
      // Record if a branch was taken so we can flush the incoming instruction next cycle
      flush_D <= pc_src_E; 

      if (pc_src_E) begin
         pc_D <= 32'b0;
         pc_plus4_D <= 32'b0;
      end else if (!stall) begin
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

/* Control Logic */
control control_i (
   .opcode (opcode),
   .funct3 (ctrl_D.funct3),
   .funct7 (funct7),
   .alu_src (ctrl_D.alu_src),
   .reg_write (ctrl_D.reg_write),
   .mem_read (ctrl_D.mem_read),
   .mem_write (ctrl_D.mem_write),
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

// ===================================================================================
// Execute Stage
// ===================================================================================
logic [31:0] rs1_data_E, rs2_data_E, imm_E;
logic [31:0] pc_E, pc_plus4_E;
logic [4:0] rd_E, rd_M, rs1_E, rs2_E;

/* ID/EX pipeline registers */
always_ff @(posedge clk or posedge rst) begin
   if (rst) begin
      ctrl_E <= '0;
      rs1_data_E <= 0;
      rs2_data_E <= 0;
      imm_E <= 0;
      rs1_E <= 0;
      rs2_E <= 0;
   end else if (pc_src_E || stall) begin
      // inject bubble in the EX stage, i.e. do nothing for one cycle
      ctrl_E <= '0;
      rd_E <= 0;

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

logic [31:0] write_data_E, op1, op2, alu_out_M;

/* Forwarding Multiplexers */
always_comb begin
    case (forward_a_E)
        2'b00: op1 = rs1_data_E; // No forwarding
        2'b01: op1 = result_W;   // Forwarded from Writeback stage
        2'b10: op1 = alu_out_M;  // Forwarded from Memory stage
        default: op1 = rs1_data_E;
    endcase

    case (forward_b_E)
        2'b00: write_data_E = rs2_data_E; // No forwarding
        2'b01: write_data_E = result_W;   // Forwarded from Writeback stage
        2'b10: write_data_E = alu_out_M;  // Forwarded from Memory stage
        default: write_data_E = rs2_data_E;
    endcase
end

/* PC Target */
assign pc_target_E = ((ctrl_E.jump_reg) ? op1 : pc_E) + imm_E;

/* ALU */
logic [31:0] alu_out_D;
logic branch_condition_E, zero_E, lt_E, ltu_E;
assign op2 = (ctrl_E.alu_src) ? imm_E : write_data_E;

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
logic [31:0] pc_plus4_M, write_data_M;

/* EX/MEM pipeline registers */
always_ff @(posedge clk or posedge rst) begin
   if (rst) begin
      ctrl_M <= '0;
      alu_out_M <= 0;
      write_data_M <= 0;
      rd_M <= 0;
      pc_plus4_M <= 0;
   end else begin
      ctrl_M.reg_write <= ctrl_E.reg_write;
      ctrl_M.mem_read  <= ctrl_E.mem_read;
      ctrl_M.mem_write <= ctrl_E.mem_write;
      ctrl_M.result_src <= ctrl_E.result_src;

      alu_out_M <= alu_out_D;
      write_data_M <= write_data_E;
      rd_M <= rd_E;
      pc_plus4_M <= pc_plus4_E;
   end
end

/* Drive External Data Memory */
assign dmem_addr  = alu_out_M;
assign dmem_wdata = write_data_M;
assign dmem_we    = ctrl_M.mem_write;
assign dmem_re    = ctrl_M.mem_read;

// ===================================================================================
// Writeback Stage
// ===================================================================================
logic [31:0] pc_plus4_W, alu_out_W, mem_out_W;

/* MEM/WB pipeline registers */
always_ff @(posedge clk or posedge rst) begin
   if (rst) begin
      alu_out_W <= 0;
      rd_W <= 0;
      ctrl_W.result_src <= 0;
      ctrl_W.reg_write <= 0;
      pc_plus4_W <= 0;
   end else begin
      alu_out_W <= alu_out_M;
      rd_W <= rd_M;
      ctrl_W.result_src <= ctrl_M.result_src;
      ctrl_W.reg_write <= ctrl_M.reg_write;
      pc_plus4_W <= pc_plus4_M;
   end
end

/* Read Data Memory */
assign mem_out_W = dmem_rdata;

/* ResultW Multiplexer */
always_comb begin
   case (ctrl_W.result_src)
      2'b00: result_W = alu_out_W;
      2'b01: result_W = mem_out_W;
      2'b10: result_W = pc_plus4_W;
      default: result_W = 0;
   endcase
end

endmodule
