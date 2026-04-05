/* verilator lint_off IMPORTSTAR */
import core_types_pkg::*;

module alu (
    input logic [31:0] op1,
    input logic [31:0] op2,
    input alu_op_t alu_op,
    output logic [31:0] out,
    output logic zero,
    output logic lt,
    output logic ltu
);

always_comb begin
   case (alu_op)
      ALU_ADD: out = op1 + op2;
      ALU_SUB: out = op1 - op2;
      ALU_SLL: out = op1 << op2[4:0];
      ALU_SLT: out = ($signed(op1) < $signed(op2)) ? 1 : 0;
      ALU_SLTU: out = (op1 < op2) ? 1 : 0;
      ALU_XOR: out = op1 ^ op2;
      ALU_SRL: out = op1 >> op2[4:0];
      ALU_SRA: out = $unsigned($signed(op1) >>> op2[4:0]);
      ALU_OR: out = op1 | op2;
      ALU_AND: out = op1 & op2;
      default: out = 0;
   endcase
end

assign zero = (out == 32'b0);
assign lt = ($signed(op1) < $signed(op2));
assign ltu = (op1 < op2);

endmodule
