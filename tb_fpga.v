`timescale 1ns/1ps
module tb_fpga;
    reg clk=0, rst=1, start=0;
    reg [1:0] sel=0; reg [7:0] mosi_data=0;
    wire sclk, mosi, cs0, cs1, cs2, done, sending, miso, miso0, miso1, miso2;
    wire [7:0] miso_data, rx0, rx1, rx2;

    spi_master m (.clk(clk), .rst(rst), .start(start), .slave_sel(sel),
        .mosi_data(mosi_data), .miso(miso), .sclk(sclk), .mosi(mosi),
        .cs0(cs0), .cs1(cs1), .cs2(cs2), .done(done),
        .miso_data(miso_data), .sending(sending));

    spi_slave_fpga s0 (.clk(clk), .rst(rst), .sclk(sclk), .cs(cs0), .mosi(mosi), .tx_data(8'hA5), .miso(miso0), .rx_data(rx0));
    spi_slave_fpga s1 (.clk(clk), .rst(rst), .sclk(sclk), .cs(cs1), .mosi(mosi), .tx_data(8'h3C), .miso(miso1), .rx_data(rx1));
    spi_slave_fpga s2 (.clk(clk), .rst(rst), .sclk(sclk), .cs(cs2), .mosi(mosi), .tx_data(8'hF0), .miso(miso2), .rx_data(rx2));

    assign miso = ~cs0 ? miso0 : ~cs1 ? miso1 : ~cs2 ? miso2 : 1'b0;
    always #5 clk = ~clk;

    task xfer(input [1:0] s, input [7:0] d);
        begin
            @(negedge clk); sel = s; mosi_data = d; start = 1;
            @(negedge clk); start = 0;
            wait(done); @(negedge clk);
            $display("sel=%0d  master got %h", s, miso_data);
        end
    endtask

    initial begin
        #20 rst = 0;
        xfer(0, 8'h5A); $display("slave0 rx = %h (expect 5a)", rx0);
        xfer(1, 8'hC3); $display("slave1 rx = %h (expect c3)", rx1);
        xfer(2, 8'h0F); $display("slave2 rx = %h (expect 0f)", rx2);
        $finish;
    end
endmodule