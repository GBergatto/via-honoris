module regfile (
   input logic clk,
   input logic [4:0] rs1,
   input logic [4:0] rs2,
   input logic [4:0] rd,
   input logic [31:0] rd_data,
   input logic write,
   output logic [31:0] rs1_data,
   output logic [31:0] rs2_data
);

logic [31:0] regs[32];

`ifdef verilator
    function [31:0] get_reg (input [4:0] index);
        // verilator public
        get_reg = regs[index];
    endfunction
`endif

// asynchronous read with write-through
always_comb begin
   if (rs1 == 5'h0) begin
      rs1_data = 32'b0; // x0
   end else if ((rs1 == rd) && write) begin
      rs1_data = rd_data; // bypass
   end else begin
      rs1_data = regs[rs1];
   end

   if (rs2 == 5'h0) begin
      rs2_data = 32'b0; // x0
   end else if ((rs2 == rd) && write) begin
      rs2_data = rd_data; // bypass
   end else begin
      rs2_data = regs[rs2];
   end
end

// synchronous write
always_ff @(posedge clk) begin
   if (write && rd != 5'h0) begin
      regs[rd] <= rd_data;
   end
end

endmodule
