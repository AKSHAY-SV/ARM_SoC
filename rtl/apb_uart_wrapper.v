`timescale 1ns / 1ps

// Thin adapter that presents uart_final's interface as a standard
// lowercase, 32-bit-paddr APB3 slave, matching every other peripheral
// in this subsystem (gpio_apb, timer_apb, spi_master_apb, plic_simple).
// uart_final itself is left untouched to minimize risk to its internals.
module apb_uart_wrapper (
    input  wire        pclk,
    input  wire        presetn,
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [31:0] paddr,
    input  wire [31:0] pwdata,
    output wire [31:0] prdata,
    output wire        pready,
    input  wire        uart_rx,
    output wire        uart_tx
);

    uart_final u_uart_final (
        .PCLK    (pclk),
        .PRESETn (presetn),
        .PSEL    (psel),
        .PENABLE (penable),
        .PWRITE  (pwrite),
        .PADDR   (paddr[7:0]),
        .PWDATA  (pwdata),
        .PRDATA  (prdata),
        .PREADY  (pready),
        .uart_rx (uart_rx),
        .uart_tx (uart_tx)
    );

endmodule
