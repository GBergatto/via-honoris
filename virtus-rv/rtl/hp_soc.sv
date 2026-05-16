module hp_soc #(
   parameter string INIT_FILE = ""
)(
    input  logic clk,
    input  logic rst,
    output logic [7:0] leds,
    // SPI Pins
    output logic spi_sclk,
    output logic spi_mosi,
    output logic spi_cs_n,
    output logic spi_dc,
    output logic spi_reset_n
);

/* verilator lint_off UNUSEDSIGNAL */
logic [31:0] imem_addr, imem_data;
logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;
logic core_stall, dmem_re;
logic [3:0] dmem_we;
logic ext_stall;
logic imem_stall, dmem_stall;
logic mtip;

assign ext_stall = imem_stall | dmem_stall;

/* RISC-V core */
hp_core core (
   .clk (clk),
   .rst (rst),
   .ext_stall (ext_stall),
   .core_stall (core_stall),
   .mtip (mtip),
   .imem_addr (imem_addr),
   .imem_data (imem_data),
   .dmem_addr (dmem_addr),
   .dmem_wdata (dmem_wdata),
   .dmem_rdata (dmem_rdata),
   .dmem_re (dmem_re),
   .dmem_we (dmem_we)
);

/* Wishbone Master 0 (Instruction Mem) */
logic [31:0] m0_adr, m0_dat_o, m0_dat_i;
logic        m0_we, m0_stb, m0_cyc, m0_ack;
logic [3:0]  m0_sel;

imem_wb instr_mem (
   .clk (clk),
   .rst (rst),
   .enable (!core_stall),
   .ext_stall (ext_stall),
   .pc (imem_addr[31:2]),
   .inst (imem_data),
   .stall (imem_stall),
   .wb_adr_o (m0_adr),
   .wb_dat_o (m0_dat_o),
   .wb_dat_i (m0_dat_i),
   .wb_we_o  (m0_we),
   .wb_sel_o (m0_sel),
   .wb_stb_o (m0_stb),
   .wb_cyc_o (m0_cyc),
   .wb_ack_i (m0_ack)
);

/* Wishbone Master 1 (Data Mem) */
logic [31:0] m1_adr, m1_dat_o, m1_dat_i;
logic        m1_we, m1_stb, m1_cyc, m1_ack;
logic [3:0]  m1_sel;

dmem_wb data_mem (
   .clk (clk),
   .rst (rst),
   .re (dmem_re),
   .we (dmem_we),
   .addr (dmem_addr),
   .wdata (dmem_wdata),
   .rdata (dmem_rdata),
   .ext_stall (ext_stall),
   .stall (dmem_stall),
   .wb_adr_o (m1_adr),
   .wb_dat_o (m1_dat_o),
   .wb_dat_i (m1_dat_i),
   .wb_we_o  (m1_we),
   .wb_sel_o (m1_sel),
   .wb_stb_o (m1_stb),
   .wb_cyc_o (m1_cyc),
   .wb_ack_i (m1_ack)
);

/* Shared Bus */
logic [31:0] s_adr, s_dat_o, s_dat_i;
logic        s_we, s_stb, s_cyc, s_ack;
logic [3:0]  s_sel;

arbiter_wb arbiter (
   .clk (clk),
   .rst (rst),
   .m0_adr_i (m0_adr),
   .m0_dat_i (m0_dat_o),
   .m0_dat_o (m0_dat_i),
   .m0_we_i  (m0_we),
   .m0_sel_i (m0_sel),
   .m0_stb_i (m0_stb),
   .m0_cyc_i (m0_cyc),
   .m0_ack_o (m0_ack),
   .m1_adr_i (m1_adr),
   .m1_dat_i (m1_dat_o),
   .m1_dat_o (m1_dat_i),
   .m1_we_i  (m1_we),
   .m1_sel_i (m1_sel),
   .m1_stb_i (m1_stb),
   .m1_cyc_i (m1_cyc),
   .m1_ack_o (m1_ack),
   .s_adr_o (s_adr),
   .s_dat_o (s_dat_o),
   .s_dat_i (s_dat_i),
   .s_we_o  (s_we),
   .s_sel_o (s_sel),
   .s_stb_o (s_stb),
   .s_cyc_o (s_cyc),
   .s_ack_i (s_ack)
);

/* Wishbone Decoder */
logic is_bram, is_led, is_clint, is_spi;
assign is_bram = (s_adr >= 32'h8000_0000);
assign is_led  = (s_adr == 32'h0100_0000);
assign is_clint = (s_adr >= 32'h0200_0000 && s_adr < 32'h0201_0000);
assign is_spi  = (s_adr >= 32'h0300_0000 && s_adr < 32'h0400_0000);

logic bram_cyc, led_cyc, clint_cyc, spi_cyc;
assign bram_cyc = s_cyc && is_bram;
assign led_cyc  = s_cyc && is_led;
assign clint_cyc = s_cyc && is_clint;
assign spi_cyc  = s_cyc && is_spi;

logic bram_stb, led_stb, clint_stb, spi_stb;
assign bram_stb = s_stb && is_bram;
assign led_stb  = s_stb && is_led;
assign clint_stb = s_stb && is_clint;
assign spi_stb  = s_stb && is_spi;

logic [31:0] bram_dat_o, led_dat_o, clint_dat_o, spi_dat_o;
logic bram_ack, led_ack, clint_ack, spi_ack;

assign s_dat_i = is_led ? led_dat_o : (is_clint ? clint_dat_o : (is_spi ? spi_dat_o : bram_dat_o));
assign s_ack   = is_led ? led_ack : (is_clint ? clint_ack : (is_spi ? spi_ack : bram_ack));

/* BRAM Slave */
sysmem_wb #(
   .AW(14),
   .INIT_FILE(INIT_FILE)
) sys_mem (
   .clk (clk),
   .rst (rst),
   /* Port A: wishbone slave*/
   .wb_adr_i (s_adr),
   .wb_dat_i (s_dat_o),
   .wb_dat_o (bram_dat_o),
   .wb_we_i  (s_we),
   .wb_sel_i (s_sel),
   .wb_stb_i (bram_stb),
   .wb_cyc_i (bram_cyc),
   .wb_ack_o (bram_ack),
   /* Port B: unassigned */
   .pb_adr_i (32'b0),
   .pb_dat_i (32'b0),
   /* verilator lint_off PINCONNECTEMPTY */
   .pb_dat_o (),
   /* verilator lint_on PINCONNECTEMPTY */
   .pb_we_i  (1'b0),
   .pb_sel_i (4'b0),
   .pb_en_i  (1'b0)
);

/* LED Slave (MMIO) */
always_ff @(posedge clk or posedge rst) begin
   if (rst) begin
      leds <= 8'b0;
      led_ack <= 1'b0;
      led_dat_o <= 32'b0;
   end else begin
      if (led_cyc && led_stb && !led_ack) begin
         led_ack <= 1'b1;
         if (s_we) begin
            leds <= ~s_dat_o[7:0];
         end
         led_dat_o <= {24'b0, leds};
      end else begin
         led_ack <= 1'b0;
      end
   end
end

/* CLINT Slave */
clint clint_i (
   .clk (clk),
   .rst (rst),
   .wb_adr_i (s_adr),
   .wb_dat_i (s_dat_o),
   .wb_dat_o (clint_dat_o),
   .wb_we_i  (s_we),
   .wb_sel_i (s_sel),
   .wb_stb_i (clint_stb),
   .wb_cyc_i (clint_cyc),
   .wb_ack_o (clint_ack),
   .mtip (mtip)
);

/* SPI Master Slave */
spi_master_wb spi_master_i (
   .wb_clk_i (clk),
   .wb_rst_i (rst),
   .wb_adr_i (s_adr),
   .wb_dat_i (s_dat_o),
   .wb_dat_o (spi_dat_o),
   .wb_sel_i (s_sel),
   .wb_we_i  (s_we),
   .wb_cyc_i (spi_cyc),
   .wb_stb_i (spi_stb),
   .wb_ack_o (spi_ack),
   .spi_sclk (spi_sclk),
   .spi_mosi (spi_mosi),
   .spi_cs_n (spi_cs_n),
   .spi_dc (spi_dc),
   .spi_reset_n (spi_reset_n)
);

endmodule
