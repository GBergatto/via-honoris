module sysmem_wb #(
   parameter int unsigned AW = 14, // 64KB
   parameter string INIT_FILE = ""
)(
   input  logic clk,
   input  logic rst,

   /* Port A: Wishbone Slave */
   /* verilator lint_off UNUSEDSIGNAL */
   input  logic [31:0] wb_adr_i,
   input  logic [31:0] wb_dat_i,
   output logic [31:0] wb_dat_o,
   input  logic        wb_we_i,
   input  logic [3:0]  wb_sel_i,
   input  logic        wb_stb_i,
   input  logic        wb_cyc_i,
   output logic        wb_ack_o,

   /* Port B: Raw BRAM (Unconnected) */
   /* verilator lint_off UNUSEDSIGNAL */
   input  logic [31:0] pb_adr_i,
   input  logic [31:0] pb_dat_i,
   output logic [31:0] pb_dat_o,
   input  logic        pb_we_i,
   input  logic [3:0]  pb_sel_i,
   input  logic        pb_en_i
);

   logic [31:0] ram [1<<AW];

   initial begin
      if (INIT_FILE != "") begin
         $readmemh(INIT_FILE, ram);
      end
   end

   logic ack_q;

   /* Wishbone Bus Control */
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
         ack_q <= 1'b0;
      end else begin
         // Acknowledge goes high 1 cycle after valid request
         if (wb_cyc_i && wb_stb_i && !ack_q) begin
            ack_q <= 1'b1;
         end else begin
            ack_q <= 1'b0;
         end
      end
   end

   assign wb_ack_o = ack_q && wb_cyc_i && wb_stb_i;

   /* Dual-port BRAM */
   always_ff @(posedge clk) begin
      /* Port A */
      if (wb_cyc_i && wb_stb_i && !ack_q) begin
         wb_dat_o <= ram[wb_adr_i[AW+1:2]];

         if (wb_we_i) begin
            if (wb_sel_i[0]) ram[wb_adr_i[AW+1:2]][7:0]   <= wb_dat_i[7:0];
            if (wb_sel_i[1]) ram[wb_adr_i[AW+1:2]][15:8]  <= wb_dat_i[15:8];
            if (wb_sel_i[2]) ram[wb_adr_i[AW+1:2]][23:16] <= wb_dat_i[23:16];
            if (wb_sel_i[3]) ram[wb_adr_i[AW+1:2]][31:24] <= wb_dat_i[31:24];
         end
      end

      /* Port B */
      if (pb_en_i) begin
         pb_dat_o <= ram[pb_adr_i[AW+1:2]];

         if (pb_we_i) begin
            if (pb_sel_i[0]) ram[pb_adr_i[AW+1:2]][7:0]   <= pb_dat_i[7:0];
            if (pb_sel_i[1]) ram[pb_adr_i[AW+1:2]][15:8]  <= pb_dat_i[15:8];
            if (pb_sel_i[2]) ram[pb_adr_i[AW+1:2]][23:16] <= pb_dat_i[23:16];
            if (pb_sel_i[3]) ram[pb_adr_i[AW+1:2]][31:24] <= pb_dat_i[31:24];
         end
      end
   end

endmodule
