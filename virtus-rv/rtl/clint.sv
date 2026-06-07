module clint (
    input  logic clk,
    input  logic rst,

    // Wishbone Slave Interface
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [31:0] wb_adr_i,
    /* verilator lint_on UNUSEDSIGNAL */
    input  logic [31:0] wb_dat_i,
    output logic [31:0] wb_dat_o,
    input  logic        wb_we_i,
    input  logic [3:0]  wb_sel_i,
    input  logic        wb_stb_i,
    input  logic        wb_cyc_i,
    output logic        wb_ack_o,

    // Interrupt Pending
    output logic mtip
);

    logic [63:0] mtime;
    logic [63:0] mtimecmp;
    logic [63:0] next_mtime;

    assign mtip = (mtime >= mtimecmp);

    always_comb begin
        next_mtime = mtime + 1;
        if (wb_cyc_i && wb_stb_i && !wb_ack_o && wb_we_i) begin
            if (wb_adr_i[15:0] == 16'hbff8) begin // MTIME_LOW
                if (wb_sel_i[0]) next_mtime[7:0]   = wb_dat_i[7:0];
                if (wb_sel_i[1]) next_mtime[15:8]  = wb_dat_i[15:8];
                if (wb_sel_i[2]) next_mtime[23:16] = wb_dat_i[23:16];
                if (wb_sel_i[3]) next_mtime[31:24] = wb_dat_i[31:24];
            end else if (wb_adr_i[15:0] == 16'hbffc) begin // MTIME_HIGH
                if (wb_sel_i[0]) next_mtime[39:32] = wb_dat_i[7:0];
                if (wb_sel_i[1]) next_mtime[47:40] = wb_dat_i[15:8];
                if (wb_sel_i[2]) next_mtime[55:48] = wb_dat_i[23:16];
                if (wb_sel_i[3]) next_mtime[63:56] = wb_dat_i[31:24];
            end
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            mtime <= 64'b0;
            mtimecmp <= 64'hFFFF_FFFF_FFFF_FFFF;
            wb_ack_o <= 1'b0;
            wb_dat_o <= 32'b0;
        end else begin
            mtime <= next_mtime;
            
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;
                if (wb_we_i) begin
                    if (wb_adr_i[15:0] == 16'h4000) begin
                        if (wb_sel_i[0]) mtimecmp[7:0]   <= wb_dat_i[7:0];
                        if (wb_sel_i[1]) mtimecmp[15:8]  <= wb_dat_i[15:8];
                        if (wb_sel_i[2]) mtimecmp[23:16] <= wb_dat_i[23:16];
                        if (wb_sel_i[3]) mtimecmp[31:24] <= wb_dat_i[31:24];
                    end else if (wb_adr_i[15:0] == 16'h4004) begin
                        if (wb_sel_i[0]) mtimecmp[39:32] <= wb_dat_i[7:0];
                        if (wb_sel_i[1]) mtimecmp[47:40] <= wb_dat_i[15:8];
                        if (wb_sel_i[2]) mtimecmp[55:48] <= wb_dat_i[23:16];
                        if (wb_sel_i[3]) mtimecmp[63:56] <= wb_dat_i[31:24];
                    end
                end else begin
                    case (wb_adr_i[15:0])
                        16'h4000: wb_dat_o <= mtimecmp[31:0];
                        16'h4004: wb_dat_o <= mtimecmp[63:32];
                        16'hbff8: wb_dat_o <= mtime[31:0];
                        16'hbffc: wb_dat_o <= mtime[63:32];
                        default:  wb_dat_o <= 32'b0;
                    endcase
                end
            end else begin
                wb_ack_o <= 1'b0;
            end
        end
    end

endmodule
