`timescale 1ns / 1ps

module apb_subsystem(
    input  wire        pclk,
    input  wire        presetn,
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [31:0] paddr,
    input  wire [31:0] pwdata,
    output wire [31:0] prdata,
    output wire        pready,
    
    // GDSII Split Pin Boundaries
    input  wire [7:0]  gpio_in,
    output wire [7:0]  gpio_out,
    output wire [7:0]  gpio_oe,

    // UART serial lines - routed straight through to the apb_uart_wrapper
    // instance below, and from there to soc_top's chip-level uart_rx/uart_tx
    // ports. Previously these were internal, undriven wires with no path
    // to the pins; the UART could be addressed over APB but could never
    // actually send/receive a real byte. Fixed by making them real ports.
    input  wire        uart_rx,
    output wire        uart_tx,

    output wire        cpu_irq
);

    wire        uart_psel,    uart_penable,    uart_pwrite;
    wire [31:0] uart_paddr,   uart_pwdata,     uart_prdata;
    wire        uart_pready;

    wire        gpio_psel,    gpio_penable,    gpio_pwrite;
    wire [31:0] gpio_paddr,   gpio_pwdata,     gpio_prdata;
    wire        gpio_pready;

    wire        timer_psel,   timer_penable,   timer_pwrite;
    wire [31:0] timer_paddr,  timer_pwdata,    timer_prdata;
    wire        timer_pready;

    wire        spi_psel,     spi_penable,     spi_pwrite;
    wire [31:0] spi_paddr,    spi_pwdata,      spi_prdata;
    wire        spi_pready;

    wire        plic_psel,    plic_penable,    plic_pwrite;
    wire [31:0] plic_paddr,   plic_pwdata,     plic_prdata;
    wire        plic_pready;

    wire timer_irq, spi_irq, gpio_irq, uart_irq;

    assign gpio_irq = 1'b0;
    assign uart_irq = 1'b0;

    apb_interconnect interconnect_u (
        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .paddr(paddr),
        .pwdata(pwdata),
        .prdata(prdata),
        .pready(pready),
        
        .gpio_psel(gpio_psel),
        .gpio_penable(gpio_penable),
        .gpio_pwrite(gpio_pwrite),
        .gpio_paddr(gpio_paddr),
        .gpio_pwdata(gpio_pwdata),
        .gpio_prdata(gpio_prdata),
        .gpio_pready(gpio_pready),
        
        .timer_psel(timer_psel),
        .timer_penable(timer_penable),
        .timer_pwrite(timer_pwrite),
        .timer_paddr(timer_paddr),
        .timer_pwdata(timer_pwdata),
        .timer_prdata(timer_prdata),
        .timer_pready(timer_pready),
        
        .spi_psel(spi_psel),
        .spi_penable(spi_penable),
        .spi_pwrite(spi_pwrite),
        .spi_paddr(spi_paddr),
        .spi_pwdata(spi_pwdata),
        .spi_prdata(spi_prdata),
        .spi_pready(spi_pready),
        
        .plic_psel(plic_psel),
        .plic_penable(plic_penable),
        .plic_pwrite(plic_pwrite),
        .plic_paddr(plic_paddr),
        .plic_pwdata(plic_pwdata),
        .plic_prdata(plic_prdata),
        .plic_pready(plic_pready),
        
        .uart_psel(uart_psel),
        .uart_penable(uart_penable),
        .uart_pwrite(uart_pwrite),
        .uart_paddr(uart_paddr),
        .uart_pwdata(uart_pwdata),
        .uart_prdata(uart_prdata),
        .uart_pready(uart_pready)
    );

    // Connected directly to split pad routing lines
    gpio_apb gpio_inst (
        .pclk(pclk),
        .presetn(presetn),
        .psel(gpio_psel),
        .penable(gpio_penable),
        .pwrite(gpio_pwrite),
        .paddr(gpio_paddr),
        .pwdata(gpio_pwdata),
        .prdata(gpio_prdata),
        .pready(gpio_pready),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .gpio_oe(gpio_oe)
    );

    timer_apb timer_inst (
        .pclk(pclk),
        .presetn(presetn),
        .psel(timer_psel),
        .penable(timer_penable),
        .pwrite(timer_pwrite),
        .paddr(timer_paddr),
        .pwdata(timer_pwdata),
        .prdata(timer_prdata),
        .pready(timer_pready),
        .irq(timer_irq)
    );

    spi_master_apb spi_inst (
        .pclk(pclk),
        .presetn(presetn),
        .psel(spi_psel),
        .penable(spi_penable),
        .pwrite(spi_pwrite),
        .paddr(spi_paddr),
        .pwdata(spi_pwdata),
        .prdata(spi_prdata),
        .pready(spi_pready),
        .sclk(),
        .mosi(),
        .miso(1'b0),
        .cs_n(),
        .irq(spi_irq)
    );

    plic_simple plic_inst (
        .pclk(pclk),
        .presetn(presetn),
        .psel(plic_psel),
        .penable(plic_penable),
        .pwrite(plic_pwrite),
        .paddr(plic_paddr),
        .pwdata(plic_pwdata),
        .prdata(plic_prdata),
        .pready(plic_pready),
        .timer_irq(timer_irq),
        .spi_irq(spi_irq),
        .gpio_irq(gpio_irq),
        .uart_irq(uart_irq),
        .cpu_irq(cpu_irq)
    );

    apb_uart_wrapper uart_inst (
        .pclk(pclk),
        .presetn(presetn),
        .psel(uart_psel),
        .penable(uart_penable),
        .pwrite(uart_pwrite),
        .paddr(uart_paddr),
        .pwdata(uart_pwdata),
        .prdata(uart_prdata),
        .pready(uart_pready),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );

endmodule