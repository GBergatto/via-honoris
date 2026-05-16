module arbiter_wb (
   input  logic clk,
   input  logic rst,

   /* Master 0: imem (lower priority) */
   input  logic [31:0] m0_adr_i,
   input  logic [31:0] m0_dat_i,
   output logic [31:0] m0_dat_o,
   input  logic        m0_we_i,
   input  logic [3:0]  m0_sel_i,
   input  logic        m0_stb_i,
   input  logic        m0_cyc_i,
   output logic        m0_ack_o,

   /* Master 1: dmem (higher priority) */
   input  logic [31:0] m1_adr_i,
   input  logic [31:0] m1_dat_i,
   output logic [31:0] m1_dat_o,
   input  logic        m1_we_i,
   input  logic [3:0]  m1_sel_i,
   input  logic        m1_stb_i,
   input  logic        m1_cyc_i,
   output logic        m1_ack_o,

   /* Shared Bus */
   output logic [31:0] s_adr_o,
   output logic [31:0] s_dat_o,
   input  logic [31:0] s_dat_i,
   output logic        s_we_o,
   output logic [3:0]  s_sel_o,
   output logic        s_stb_o,
   output logic        s_cyc_o,
   input  logic        s_ack_i
);

   logic locked;
   logic current_grant; // 0 for m0, 1 for m1

   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
         locked <= 1'b0;
         current_grant <= 1'b0;
      end else begin
         if (locked) begin
            // Drop the lock if the currently-granted master drops its cycle signal
            if ((current_grant == 1'b1 && !m1_cyc_i) ||
                (current_grant == 1'b0 && !m0_cyc_i)) begin
               locked <= 1'b0;
            end
         end else if (m1_cyc_i || m0_cyc_i) begin
            // Lock the bus and save the winner
            locked <= 1'b1;
            current_grant <= m1_cyc_i ? 1'b1 : 1'b0;
         end
      end
   end

   // If locked, use the saved grant. Otherwise, prioritize m1.
   logic grant;
   assign grant = locked ? current_grant : (m1_cyc_i ? 1'b1 : 1'b0);

   assign s_adr_o = grant ? m1_adr_i : m0_adr_i;
   assign s_dat_o = grant ? m1_dat_i : m0_dat_i;
   assign s_we_o  = grant ? m1_we_i  : m0_we_i;
   assign s_sel_o = grant ? m1_sel_i : m0_sel_i;
   assign s_stb_o = grant ? m1_stb_i : m0_stb_i;
   assign s_cyc_o = grant ? m1_cyc_i : m0_cyc_i;

   assign m1_dat_o = s_dat_i;
   assign m0_dat_o = s_dat_i;

   assign m1_ack_o = grant ? s_ack_i : 1'b0;
   assign m0_ack_o = !grant ? s_ack_i : 1'b0;

endmodule
