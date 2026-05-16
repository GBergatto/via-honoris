module buttons_wb (
   input  logic        wb_clk_i,
   input  logic        wb_rst_i,
   /* verilator lint_off UNUSEDSIGNAL */
   input  logic [31:0] wb_adr_i,
   input  logic [31:0] wb_dat_i,
   input  logic [3:0]  wb_sel_i,
   input  logic        wb_we_i,
   /* verilator lint_on UNUSEDSIGNAL */
   output logic [31:0] wb_dat_o,
   input  logic        wb_cyc_i,
   input  logic        wb_stb_i,
   output logic        wb_ack_o,

   input  logic [3:0]  buttons
);

   logic ack_q;
   assign wb_ack_o = ack_q;

   // Two-stage synchronizer to prevent metastability
   logic [3:0] sync1;
   logic [3:0] sync2;

   always_ff @(posedge wb_clk_i or posedge wb_rst_i) begin
      if (wb_rst_i) begin
         sync1 <= 4'b1111; // Default to unpressed (PULLUP)
         sync2 <= 4'b1111;
         ack_q <= 1'b0;
         wb_dat_o <= 32'b0;
      end else begin
         // Shift inputs through the synchronizer
         sync1 <= buttons;
         sync2 <= sync1;

         ack_q <= 1'b0;
         if (wb_cyc_i && wb_stb_i && !ack_q) begin
            ack_q <= 1'b1;
            // PULLMODE=UP means unpressed = 1, pressed = 0.
            // Invert the synchronized value so that pressed = 1.
            wb_dat_o <= {28'b0, ~sync2};
         end
      end
   end

endmodule
