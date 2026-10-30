module spi_top (
    input  wire clk,
    input  wire btn_rst,        // BTN0
    input  wire btn_start,      // BTN1
    input  wire [1:0] sw_sel,   // SW1:SW0
    input  wire sw_nibble,      // SW2
    output wire [3:0] led
);
    // button synchronizer + debounce + one-clock pulse
    reg [1:0]  sync = 0;
    reg [19:0] cnt = 0;
    reg        stable = 0, stable_d = 0;
    always @(posedge clk) begin
        sync <= {sync[0], btn_start};
        if (sync[1] == stable) cnt <= 0;
        else begin
            cnt <= cnt + 1;
            if (&cnt) stable <= sync[1];
        end
        stable_d <= stable;
    end
    wire start_pulse = stable & ~stable_d;

    wire sclk, mosi, cs0, cs1, cs2, done, sending;
    wire miso, miso0, miso1, miso2;
    wire [7:0] miso_data, rx0, rx1, rx2;

    wire [7:0] tx0 = 8'hA5, tx1 = 8'h3C, tx2 = 8'hF0;
    reg  [7:0] mosi_data;
    always @(*) case (sw_sel)
        2'd0:    mosi_data = 8'h5A;
        2'd1:    mosi_data = 8'hC3;
        default: mosi_data = 8'h0F;
    endcase

    spi_master m (.clk(clk), .rst(btn_rst), .start(start_pulse),
        .slave_sel(sw_sel), .mosi_data(mosi_data), .miso(miso),
        .sclk(sclk), .mosi(mosi), .cs0(cs0), .cs1(cs1), .cs2(cs2),
        .done(done), .miso_data(miso_data), .sending(sending));

    spi_slave_fpga s0 (.clk(clk), .rst(btn_rst), .sclk(sclk), .cs(cs0), .mosi(mosi), .tx_data(tx0), .miso(miso0), .rx_data(rx0));
    spi_slave_fpga s1 (.clk(clk), .rst(btn_rst), .sclk(sclk), .cs(cs1), .mosi(mosi), .tx_data(tx1), .miso(miso1), .rx_data(rx1));
    spi_slave_fpga s2 (.clk(clk), .rst(btn_rst), .sclk(sclk), .cs(cs2), .mosi(mosi), .tx_data(tx2), .miso(miso2), .rx_data(rx2));

    assign miso = ~cs0 ? miso0 : ~cs1 ? miso1 : ~cs2 ? miso2 : 1'b0;

    assign led = sw_nibble ? miso_data[7:4] : miso_data[3:0];
endmodule
