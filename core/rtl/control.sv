/* verilator lint_off IMPORTSTAR */
import core_types_pkg::*;

module control (
   input opcode_e opcode,
   /* verilator lint_off UNUSEDSIGNAL */
   input logic [2:0] funct3,
   /* verilator lint_off UNUSEDSIGNAL */
   input logic [6:0] funct7,
   output logic alu_src,
   output logic reg_write,
   output logic mem_write,
   output logic mem_read,
   output logic [1:0] result_src,
   output logic branch,
   output logic jump,
   output logic jump_reg
);

// ALU source op2 is Immediate for everything except R-Types and Branches
assign alu_src = (opcode != OPC_OP) && (opcode != OPC_BRANCH);

always_comb begin
   case (opcode)
      OPC_BRANCH, OPC_STORE:
         reg_write = 1'b0;
      default:
         reg_write = 1'b1;
   endcase
end

assign mem_write = (opcode == OPC_STORE);
assign mem_read  = (opcode == OPC_LOAD);

always_comb begin
   case (opcode)
      OPC_JAL, OPC_JALR:
         result_src = 2'b10;
      OPC_LOAD:
         result_src = 2'b01;
      default: result_src = 2'b00;
   endcase
end

assign jump     = (opcode == OPC_JAL) || (opcode == OPC_JALR);
assign branch   = (opcode == OPC_BRANCH);
assign jump_reg = (opcode == OPC_JALR);

endmodule
