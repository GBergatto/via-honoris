module dmem_wb (
   input  logic clk,
   input  logic rst,
   input  logic ext_stall, // global stall from SOC

   /* Core interface */
   input  logic        re,
   input  logic [3:0]  we,
   /* verilator lint_off UNUSEDSIGNAL */
   input  logic [31:0] addr,
   input  logic [31:0] wdata,
   output logic [31:0] rdata,
   output logic        stall, // local stall request

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

`ifdef verilator
    // Expose signals for the tohost testbench hook
    function logic [3:0] get_we();
        // verilator public
        get_we = we;
    endfunction

    function logic [31:0] get_addr();
        // verilator public
        get_addr = addr;
    endfunction

    function logic [31:0] get_wdata();
        // verilator public
        get_wdata = wdata;
    endfunction
`endif

logic [31:0] wb_fetched_data;
logic wb_valid;
logic active_req;

assign active_req = re || (|we);

always_ff @(posedge clk or posedge rst) begin
   if (rst) begin
      wb_fetched_data <= 32'b0;
      wb_valid <= 1'b0;
   end else begin
      if (wb_cyc_o && wb_stb_o && wb_ack_i) begin
         if (!ext_stall) begin
            wb_valid <= 1'b0;
         end else begin
            wb_fetched_data <= wb_dat_i;
            wb_valid <= 1'b1;
         end
      end else if (!ext_stall) begin
         wb_valid <= 1'b0;
      end
   end
end

assign wb_adr_o = addr;
assign wb_dat_o = wdata;
assign wb_we_o  = (|we);
assign wb_sel_o = (|we) ? we : 4'b1111;

assign wb_cyc_o = active_req && !rst && !wb_valid;
assign wb_stb_o = active_req && !rst && !wb_valid;

assign stall = active_req && !rst && !wb_valid && !wb_ack_i;

always_ff @(posedge clk or posedge rst) begin
   if (rst) begin
      rdata <= 32'b0;
   end else if (!ext_stall) begin
      rdata <= (wb_cyc_o && wb_stb_o && wb_ack_i) ? wb_dat_i : wb_fetched_data;
   end
end

endmodule
