`timescale 1ns / 1ps

// Centralized APB address decoder.
// Owns the entire system peripheral memory map; peripheral slaves never
// compare addresses themselves, they only see the sub-range of paddr and
// a qualified psel/penable.
module apb_interconnect (
    input wire           psel,
    input wire           penable,
    input wire           pwrite,
    input wire  [31:0]   paddr,
    input wire  [31:0]   pwdata,
    output wire [31:0]   prdata,
    output wire          pready,

    // UART
    output wire          uart_psel,
    output wire          uart_penable,
    output wire          uart_pwrite,
    output wire [31:0]   uart_paddr,
    output wire [31:0]   uart_pwdata,
    input wire  [31:0]   uart_prdata,
    input wire           uart_pready,

    // GPIO
    output wire          gpio_psel,
    output wire          gpio_penable,
    output wire          gpio_pwrite,
    output wire [31:0]   gpio_paddr,
    output wire [31:0]   gpio_pwdata,
    input wire  [31:0]   gpio_prdata,
    input wire           gpio_pready,

    // TIMER
    output wire          timer_psel,
    output wire          timer_penable,
    output wire          timer_pwrite,
    output wire [31:0]   timer_paddr,
    output wire [31:0]   timer_pwdata,
    input wire  [31:0]   timer_prdata,
    input wire           timer_pready,

    // SPI
    output wire          spi_psel,
    output wire          spi_penable,
    output wire          spi_pwrite,
    output wire [31:0]   spi_paddr,
    output wire [31:0]   spi_pwdata,
    input wire  [31:0]   spi_prdata,
    input wire           spi_pready,

    // PLIC
    output wire          plic_psel,
    output wire          plic_penable,
    output wire          plic_pwrite,
    output wire [31:0]   plic_paddr,
    output wire [31:0]   plic_pwdata,
    input wire  [31:0]   plic_prdata,
    input wire           plic_pready
);

    // System peripheral memory map - single source of truth.
    // Each peripheral owns a 4KB (0x1000) window.
    localparam [31:0] PERIPH_WINDOW_MASK = 32'hFFFF_F000;

    localparam [31:0] GPIO_BASE  = 32'h0000_1000;
    localparam [31:0] TIMER_BASE = 32'h0000_2000;
    localparam [31:0] SPI_BASE   = 32'h0000_3000;
    localparam [31:0] PLIC_BASE  = 32'h0000_4000;
    localparam [31:0] UART_BASE  = 32'h0000_5000;

    wire sel_gpio  = ((paddr & PERIPH_WINDOW_MASK) == GPIO_BASE);
    wire sel_timer = ((paddr & PERIPH_WINDOW_MASK) == TIMER_BASE);
    wire sel_spi   = ((paddr & PERIPH_WINDOW_MASK) == SPI_BASE);
    wire sel_plic  = ((paddr & PERIPH_WINDOW_MASK) == PLIC_BASE);
    wire sel_uart  = ((paddr & PERIPH_WINDOW_MASK) == UART_BASE);

    // Gated control outputs
    assign gpio_psel    = psel & sel_gpio;
    assign gpio_penable = penable & sel_gpio;
    assign gpio_pwrite  = pwrite;
    assign gpio_paddr   = paddr;
    assign gpio_pwdata  = pwdata;

    assign timer_psel    = psel & sel_timer;
    assign timer_penable = penable & sel_timer;
    assign timer_pwrite  = pwrite;
    assign timer_paddr   = paddr;
    assign timer_pwdata  = pwdata;

    assign spi_psel    = psel & sel_spi;
    assign spi_penable = penable & sel_spi;
    assign spi_pwrite  = pwrite;
    assign spi_paddr   = paddr;
    assign spi_pwdata  = pwdata;

    assign plic_psel    = psel & sel_plic;
    assign plic_penable = penable & sel_plic;
    assign plic_pwrite  = pwrite;
    assign plic_paddr   = paddr;
    assign plic_pwdata  = pwdata;

    assign uart_psel    = psel & sel_uart;
    assign uart_penable = penable & sel_uart;
    assign uart_pwrite  = pwrite;
    assign uart_paddr   = paddr;
    assign uart_pwdata  = pwdata;

    // Unified system bus response mux
    assign pready = sel_gpio  ? gpio_pready  :
                    sel_timer ? timer_pready :
                    sel_spi   ? spi_pready   :
                    sel_plic  ? plic_pready  :
                    sel_uart  ? uart_pready  : 1'b1;

    assign prdata = sel_gpio  ? gpio_prdata  :
                    sel_timer ? timer_prdata :
                    sel_spi   ? spi_prdata   :
                    sel_plic  ? plic_prdata  :
                    sel_uart  ? uart_prdata  : 32'hDEADBEEF;

endmodule
