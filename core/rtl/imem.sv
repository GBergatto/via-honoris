module imem #(
   parameter int unsigned AW = 8, // address width
   parameter string INIT_FILE = ""
)(
   input logic clk,
   input logic rst,
   input logic enable,
   /* verilator lint_off UNUSEDSIGNAL */
   input logic [29:0] pc,
   output logic [31:0] inst
);

logic [31:0] rom [1<<AW];

initial begin
   // load program
   if (INIT_FILE != "") begin
       $readmemh(INIT_FILE, rom);
   end
end

// synchronous read
always_ff @(posedge clk) begin
   if (rst)
      inst <= 32'h0; // don't read while rst is high
   else if (enable) begin
      // use only the low AW bits of PC as the ROM index
      inst <= rom[pc[AW-1:0]];
   end
end

endmodule
