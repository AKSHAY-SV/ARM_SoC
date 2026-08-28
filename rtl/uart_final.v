`timescale 1ns / 1ps

module uart_final(

    input wire PCLK,
    input wire PRESETn,

    input wire PSEL,
    input wire PENABLE,
    input wire PWRITE,

    input wire [7:0]  PADDR,
    input wire [31:0] PWDATA,

    output wire [31:0] PRDATA,
    output wire PREADY,

    input wire uart_rx,
    output wire uart_tx

);

apb_uart uart_inst(

    .PCLK(PCLK),
    .PRESETn(PRESETn),

    .PSEL(PSEL),
    .PENABLE(PENABLE),
    .PWRITE(PWRITE),

    .PADDR(PADDR),
    .PWDATA(PWDATA),

    .PRDATA(PRDATA),
    .PREADY(PREADY),

    .uart_rx(uart_rx),
    .uart_tx(uart_tx)

);

endmodule
