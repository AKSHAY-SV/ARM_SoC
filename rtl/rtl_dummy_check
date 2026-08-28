`timescale 1ns / 1ps

module apb_uart(

    input wire PCLK,
    input wire PRESETn,

    input wire PSEL,
    input wire PENABLE,
    input wire PWRITE,

    input wire [7:0] PADDR,
    input wire [31:0] PWDATA,

    output wire [31:0] PRDATA,
    output wire PREADY,

    input wire uart_rx,
    output wire uart_tx

);

wire rst;
assign rst = ~PRESETn;

wire wr_en;
wire rd_en;

assign wr_en = PSEL & PENABLE & PWRITE;
assign rd_en = PSEL & PENABLE & ~PWRITE;

wire [7:0] tx_data;
wire tx_start;
wire [15:0] baud_div;

wire [7:0] rx_data;
wire rx_valid;
wire tx_busy;

uart_regs regs_inst(

    .clk(PCLK),
    .rst(rst),

    .wr_en(wr_en),
    .rd_en(rd_en),

    .addr(PADDR[3:0]),
    .wdata(PWDATA),

    .rdata(PRDATA),

    .rx_data(rx_data),
    .rx_valid(rx_valid),
    .tx_busy(tx_busy),

    .tx_data(tx_data),
    .tx_start(tx_start),

    .baud_div(baud_div)

);

uart_top uart_inst(

    .clk(PCLK),
    .rst(rst),

    .tx_start(tx_start),
    .tx_data(tx_data),

    .rx_data(rx_data),
    .rx_valid(rx_valid),

    .tx_busy(tx_busy),

    .uart_tx(uart_tx),
    .uart_rx(uart_rx)

);

assign PREADY = 1'b1;

endmodule
