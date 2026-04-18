module imem_wb (
   input  logic clk,
   input  logic rst,
   input  logic enable,
   input  logic ext_stall, // global stall from SOC

   /* Core interface */
   /* verilator lint_off UNUSEDSIGNAL */
   input  logic [29:0] pc,
   output logic [31:0] inst,
   output logic stall, // local stall request

   /* Wishbone Master Interface */
   output logic [31:0] wb_adr_o,
   output logic [31:0] wb_dat_o,
   input  logic [31:0] wb_dat_i,
   output logic        wb_we_o,
   output logic [3:0]  wb_sel_o,
   output logic        wb_stb_o,
   output logic        wb_cyc_o,
   input  logic        wb_ack_i
);

logic wb_valid;
logic [31:0] wb_fetched_data;

always_ff @(posedge clk or posedge rst) begin
   if (rst) begin
      wb_fetched_data <= 32'b0;
      wb_valid <= 1'b0;
   end else begin
      if (wb_cyc_o && wb_stb_o && wb_ack_i) begin
         if (!ext_stall && enable) begin
            wb_valid <= 1'b0;
         end else begin
            wb_fetched_data <= wb_dat_i;
            wb_valid <= 1'b1;
         end
      end else if (!ext_stall && enable) begin
         wb_valid <= 1'b0;
      end
   end
end

assign wb_adr_o = {pc, 2'b00};
assign wb_dat_o = 32'b0;
assign wb_we_o  = 1'b0;
assign wb_sel_o = 4'b1111;

assign wb_cyc_o = enable && !rst && !wb_valid;
assign wb_stb_o = enable && !rst && !wb_valid;

assign stall = enable && !rst && !wb_valid && !wb_ack_i;

always_ff @(posedge clk or posedge rst) begin
   if (rst) begin
      inst <= 32'b0;
   end else if (!ext_stall && enable) begin
      inst <= (wb_cyc_o && wb_stb_o && wb_ack_i) ? wb_dat_i : wb_fetched_data;
   end
end

endmodule
