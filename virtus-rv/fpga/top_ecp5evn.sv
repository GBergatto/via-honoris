module top_ecp5evn(
    input  wire [3:0] button,
    output wire [7:0] led,
    output wire spi_sclk,
    output wire spi_mosi,
    output wire spi_cs_n,
    output wire spi_dc,
    output wire spi_reset_n
);
    // 1. Internal Clock
    wire clk;
    defparam OSCInst.DIV = 128;
    OSCG OSCInst(.OSC(clk));

    // 2. Power-on Reset
    reg [3:0] rst_cnt = 0;
    wire rst = ~&rst_cnt;
    always @(posedge clk) begin
        if (rst) rst_cnt <= rst_cnt + 1;
    end

    // 3. Connect the SoC
    wire [7:0] soc_leds;
    hp_soc #(
        .INIT_FILE("../../sw/build/firmware.hex")
    ) system (
        .clk (clk),
        .rst (rst),
        .buttons (button),
        .leds (soc_leds),
        .spi_sclk (spi_sclk),
        .spi_mosi (spi_mosi),
        .spi_cs_n (spi_cs_n),
        .spi_dc (spi_dc),
        .spi_reset_n (spi_reset_n)
    );

    assign led = soc_leds;
endmodule
