module dmem #(
   parameter int unsigned AW = 8 // address width
)(
   input logic clk,
   input logic re, // read enable
   input logic [3:0] we, // write enable
   /* verilator lint_off UNUSEDSIGNAL */
   input logic [31:0] addr,
   input logic [31:0] wdata,
   output logic [31:0] rdata
);

logic [31:0] ram [1<<AW];

`ifdef verilator
    // Expose signals for the tohost testbench hook
    function logic get_we();
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

// synchronous read + write
always_ff @(posedge clk) begin
   if (re) begin
      rdata <= ram[addr[AW+1:2]];
   end else begin
      rdata <= 32'h0;
   end
   if (we[0]) ram[addr[AW+1:2]][7:0]   <= wdata[7:0];
   if (we[1]) ram[addr[AW+1:2]][15:8]  <= wdata[15:8];
   if (we[2]) ram[addr[AW+1:2]][23:16] <= wdata[23:16];
   if (we[3]) ram[addr[AW+1:2]][31:24] <= wdata[31:24];
end

endmodule
