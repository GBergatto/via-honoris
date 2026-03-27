module hp_soc #(
   parameter string INIT_FILE = ""
)(
    input  logic clk,
    input  logic rst,
    output logic [7:0] leds
);

/* verilator lint_off UNUSEDSIGNAL */
logic [31:0] imem_addr, imem_data;
logic [31:0] dmem_addr, dmem_wdata, dmem_rdata, rdata;
logic core_stall, dmem_re;
logic [3:0] dmem_we;

/* RISC-V core */
hp_core core (
   .clk (clk),
   .rst (rst),
   .core_stall (core_stall),
   .imem_addr (imem_addr),
   .imem_data (imem_data),
   .dmem_addr (dmem_addr),
   .dmem_wdata (dmem_wdata),
   .dmem_rdata (rdata),
   .dmem_re (dmem_re),
   .dmem_we (dmem_we)
);

/* Instruction memory */
imem #(
   .AW (13),
   .INIT_FILE (INIT_FILE)
) instr_mem (
   .clk (clk),
   .rst (rst),
   .enable (!core_stall),
   .pc (imem_addr[31:2]),
   .inst (imem_data)
);

wire is_led = (dmem_addr == 32'h0100_0000);

/* Data memory */
dmem #(13) data_mem (
   .clk (clk),
   .re (dmem_re),
   .we (is_led ? 4'b0000 : dmem_we),
   .addr (dmem_addr),
   .wdata (dmem_wdata),
   .rdata (dmem_rdata)
);

/* LED MMIO register */
always_ff @(posedge clk) begin
   if (rst) begin
      leds <= 8'b0;
   end else if (|dmem_we && is_led) begin
      leds <= ~dmem_wdata[7:0]; // Catch the write!
   end
end

assign rdata = is_led ? {24'b0, leds} : dmem_rdata;

endmodule
