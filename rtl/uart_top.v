`timescale 1ns / 1ps

module uart_top(

    input wire clk,
    input wire rst,

    input wire tx_start,
    input wire [7:0] tx_data,

    output wire [7:0] rx_data,
    output wire rx_valid,
    output wire uart_tx,
    input  wire uart_rx,

    output wire tx_busy

);

wire baud_tick;
wire [15:0] baud_div;
assign baud_div = 16'd10;

baud_gen baud_inst(
    .clk(clk),
    .rst(rst),
    .baud_div(baud_div),
    .baud_tick(baud_tick)
);

uart_tx tx_inst(
    .clk(clk),
    .rst(rst),
    .baud_tick(baud_tick),

    .tx_start(tx_start),
    .tx_data(tx_data),

    .tx(uart_tx),
    .busy(tx_busy)
);

uart_rx rx_inst(
    .clk(clk),
    .rst(rst),
    .baud_tick(baud_tick),

    .rx(uart_rx),

    .rx_data(rx_data),
    .rx_valid(rx_valid)
);

endmodule
