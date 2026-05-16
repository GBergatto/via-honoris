module spi_master_wb (
   // Wishbone Signals
   input  logic        wb_clk_i,
   input  logic        wb_rst_i,
   /* verilator lint_off UNUSEDSIGNAL */
   input  logic [31:0] wb_adr_i,
   input  logic [31:0] wb_dat_i,
   output logic [31:0] wb_dat_o,
   input  logic [3:0]  wb_sel_i,
   /* verilator lint_on UNUSEDSIGNAL */
   input  logic        wb_we_i,
   input  logic        wb_cyc_i,
   input  logic        wb_stb_i,
   output logic        wb_ack_o,

   // Physical SPI Pins
   output logic        spi_sclk,
   output logic        spi_mosi,
   output logic        spi_cs_n,
   output logic        spi_dc,
   output logic        spi_reset_n
);

   typedef enum logic [1:0] {
      IDLE,
      SHIFT_LOW,
      SHIFT_HIGH
   } state_e;

   state_e state;

   logic [15:0] shift_reg;
   logic [4:0]  bits_left;

   // Control bits
   logic ctrl_dc;
   logic ctrl_cs_n;
   logic ctrl_reset_n;

   assign spi_dc      = ctrl_dc;
   assign spi_cs_n    = ctrl_cs_n;
   assign spi_reset_n = ctrl_reset_n;

   assign spi_sclk = (state == SHIFT_HIGH);
   assign spi_mosi = shift_reg[15];

   logic ack_q;
   assign wb_ack_o = ack_q;

   localparam logic [7:0] ADDR_SPI_DATA = 8'h00;
   localparam logic [7:0] ADDR_SPI_CTRL = 8'h04;

   always_ff @(posedge wb_clk_i or posedge wb_rst_i) begin
      if (wb_rst_i) begin
         state        <= IDLE;
         shift_reg    <= '0;
         bits_left    <= '0;
         ctrl_dc      <= 1'b0;
         ctrl_cs_n    <= 1'b1;
         ctrl_reset_n <= 1'b0;
         ack_q        <= 1'b0;
         wb_dat_o     <= '0;
      end else begin
         ack_q <= 1'b0; // Default to no-ack

         case (state)
            IDLE: begin
               if (wb_cyc_i && wb_stb_i && !ack_q) begin
                  ack_q <= 1'b1;

                  if (wb_we_i) begin
                     // Write
                     if (wb_adr_i[7:0] == ADDR_SPI_DATA) begin
                        if (wb_sel_i[1] || wb_sel_i[3]) begin
                           // 16-bit write
                           shift_reg <= wb_dat_i[15:0];
                           bits_left <= 5'd16;
                        end else begin
                           // 8-bit write
                           shift_reg <= {wb_dat_i[7:0], 8'h00};
                           bits_left <= 5'd8;
                        end
                        state <= SHIFT_LOW;
                     end else if (wb_adr_i[7:0] == ADDR_SPI_CTRL) begin
                        if (wb_sel_i[0]) begin
                           ctrl_dc      <= wb_dat_i[0];
                           ctrl_cs_n    <= wb_dat_i[1];
                           ctrl_reset_n <= wb_dat_i[2];
                        end
                     end
                  end else begin
                     // Read
                     wb_dat_o <= '0;
                     if (wb_adr_i[7:0] == ADDR_SPI_CTRL) begin
                        wb_dat_o[0] <= ctrl_dc;
                        wb_dat_o[1] <= ctrl_cs_n;
                        wb_dat_o[2] <= ctrl_reset_n;
                        wb_dat_o[3] <= 1'b0; // BUSY is 0 in IDLE
                     end
                  end
               end
            end

            SHIFT_LOW: begin
               state <= SHIFT_HIGH;
            end

            SHIFT_HIGH: begin
               shift_reg <= {shift_reg[14:0], 1'b0};
               bits_left <= bits_left - 5'd1;

               if (bits_left == 5'd1) begin
                  state <= IDLE;
               end else begin
                  state <= SHIFT_LOW;
               end
            end

            default: state <= IDLE;
         endcase
      end
   end

endmodule
