module spi_slave_fpga (
    input  wire       clk,       // system clock (100 MHz)
    input  wire       rst,       // active-high reset
    input  wire       sclk,      // SPI clock from master
    input  wire       cs,        // active-low chip select
    input  wire       mosi,      // data from master
    input  wire [7:0] tx_data,   // byte this slave sends to the master
    output wire       miso,      // data to master
    output reg  [7:0] rx_data    // byte received from the master
);

    reg       sclk_d, cs_d;
    reg [7:0] tx_shift;

    wire sclk_rise = sclk & ~sclk_d;
    wire sclk_fall = ~sclk & sclk_d;
    wire cs_fall   = ~cs & cs_d;

    assign miso = tx_shift[7];   // MSB is always on the line

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sclk_d   <= 1'b0;
            cs_d     <= 1'b1;
            tx_shift <= 8'h00;
            rx_data  <= 8'h00;
        end else begin
            sclk_d <= sclk;
            cs_d   <= cs;

            if (cs_fall) begin
                tx_shift <= tx_data;                       // load on select
            end else if (!cs) begin
                if (sclk_rise) rx_data  <= {rx_data[6:0], mosi};  // sample MOSI
                if (sclk_fall) tx_shift <= {tx_shift[6:0], 1'b0}; // next MISO bit
            end
        end
    end

endmodule
