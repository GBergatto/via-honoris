/* verilator lint_off IMPORTSTAR */
import core_types_pkg::*;

module immgen (
   /* verilator lint_off UNUSEDSIGNAL */
   input logic [31:0] inst,
   output logic [31:0] imm
);

opcode_e opcode;
assign opcode = opcode_e'(inst[6:0]);

always_comb begin
   case (opcode)
      OPC_OP_IMM, OPC_LOAD, OPC_JALR:
         imm = {{20{inst[31]}}, inst[31:20]};

      OPC_STORE:
         imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};

      OPC_BRANCH:
         imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};

      OPC_JAL:
         imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

      // TODO: support U-type

      default:
         imm = 32'b0;
   endcase
end

endmodule
