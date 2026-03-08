module top_ecp5evn(
    output wire [7:0] led
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
        .INIT_FILE("../fw/firmware.hex")
    ) system (
        .clk (clk),
        .rst (rst),
        .leds (soc_leds)
    );

    assign led = soc_leds;
endmodule
