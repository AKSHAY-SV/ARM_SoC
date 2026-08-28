`timescale 1ns / 1ps

// ====================================================================
// Main System-on-Chip Module
// ====================================================================
//
// GPIO NOTE (GDSII-flow fix): gpio is exposed as three unidirectional
// ports (gpio_in / gpio_out / gpio_oe) instead of a single bidirectional
// `inout`. A previous version wrapped an internal tristate `GPIOPAD`
// behavioral model (`assign PAD = OE ? OUT : 1'bz;`) around this signal,
// which is not synthesizable against sky130_fd_sc_hd (no tristate cells
// in that library). Tristate/pad handling belongs to the physical IO
// ring, not this digital macro's RTL - the integrator (e.g. Caravel's
// user-project harness, or a board-level pad cell) is responsible for
// combining gpio_out/gpio_oe into a real bidirectional pin and feeding
// the pin's level back in on gpio_in.
module soc_top (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  gpio_in,
    output wire [7:0]  gpio_out,
    output wire [7:0]  gpio_oe,
    input  wire        uart_rx,
    output wire        uart_tx
);

    // System memory map: single-source-of-truth for the APB window.
    // Fine-grained per-peripheral decode lives in apb_interconnect.v.
    localparam [31:0] APB_BASE  = 32'h0000_1000;
    localparam [31:0] APB_LIMIT = 32'h0000_5FFF;

    wire [31:0] instr_addr;
    wire [31:0] instr_rdata;
    wire [31:0] data_addr;
    wire [31:0] data_wdata;
    wire [31:0] data_rdata;
    wire        data_we;
    wire        data_re;
    wire [31:0] ram_rdata;
    wire [31:0] apb_prdata;
    wire        apb_pready;
    wire        cpu_irq;
    wire [1:0]  mem_size;
    wire        mem_signed;

    // Synchronized system reset: asserted asynchronously with rst, released
    // synchronously to clk (see reset_sync.v). Removes the reset-recovery/
    // removal timing risk of a combinational presetn = ~rst.
    wire presetn;
    wire rst_sync = ~presetn; // active-high equivalent, for CPU pipeline reset

    reset_sync u_reset_sync (
        .clk       (clk),
        .async_rst (rst),
        .sync_rstn (presetn)
    );

    datapath cpu (
        .clk(clk),
        .rst(rst_sync),
        .pc_out(),
        .alu_result(),
        .instr(),
        .reg_write(),
        .instr_addr(instr_addr),
        .instr_rdata(instr_rdata),
        .data_addr(data_addr),
        .data_wdata(data_wdata),
        .data_we(data_we),
        .data_re(data_re),
        .mem_size(mem_size),
        .mem_signed(mem_signed),
        .data_rdata(data_rdata)
    );

    instr_mem #(.DEPTH(512), .ADDR_HI(10)) imem (
        .addr(instr_addr),
        .instr(instr_rdata)
    );

    wire ram_sel;
    wire apb_sel;

    assign apb_sel = (data_addr >= APB_BASE) && (data_addr <= APB_LIMIT);
    assign ram_sel = ~apb_sel;

    data_mem dmem (
        .clk(clk),
        .we(data_we & ram_sel),
        .re(data_re & ram_sel),
        .mem_size(mem_size),
        .mem_signed(mem_signed),
        .addr(data_addr),
        .wd(data_wdata),
        .rd(ram_rdata)
    );

    // APB SETUP/ACCESS phase generator.
    // paddr/pwdata/pwrite are captured once, on the cycle the request is
    // first seen, and held stable through both the SETUP and ACCESS
    // phases. Previously psel/penable were registered (delayed) versions
    // of the request while paddr/pwdata/pwrite were wired straight from
    // the CPU's *current* cycle - since the pipeline issues a new
    // data_addr every cycle, that meant the peripheral would see the
    // address/data of whatever instruction happened to be in MEM by the
    // time psel/penable finally asserted, not the instruction that
    // actually requested the transfer. Also, PSEL now stays asserted for
    // the full SETUP+ACCESS window instead of dropping one cycle before
    // PENABLE, which is what the APB3 protocol requires.
    localparam APB_IDLE   = 2'd0;
    localparam APB_SETUP  = 2'd1;
    localparam APB_ACCESS = 2'd2;

    reg  [1:0]  apb_state;
    reg  [31:0] apb_paddr_reg;
    reg  [31:0] apb_pwdata_reg;
    reg         apb_pwrite_reg;

    always @(posedge clk or negedge presetn) begin
        if (!presetn) begin
            apb_state      <= APB_IDLE;
            apb_paddr_reg  <= 32'h0;
            apb_pwdata_reg <= 32'h0;
            apb_pwrite_reg <= 1'b0;
        end else begin
            case (apb_state)
                APB_IDLE: begin
                    if (apb_sel && (data_we || data_re)) begin
                        apb_paddr_reg  <= data_addr;
                        apb_pwdata_reg <= data_wdata;
                        apb_pwrite_reg <= data_we;
                        apb_state      <= APB_SETUP;
                    end
                end
                APB_SETUP: begin
                    apb_state <= APB_ACCESS;
                end
                APB_ACCESS: begin
                    // Holds here (extending the ACCESS phase) for as long
                    // as the slave reports not-ready; every peripheral in
                    // this subsystem currently ties pready to 1'b1, so
                    // this resolves in a single cycle today, but a future
                    // slave with real wait states is now handled correctly
                    // instead of silently ignored.
                    if (apb_pready)
                        apb_state <= APB_IDLE;
                end
                default: apb_state <= APB_IDLE;
            endcase
        end
    end

    wire apb_psel_reg    = (apb_state == APB_SETUP) || (apb_state == APB_ACCESS);
    wire apb_penable_reg = (apb_state == APB_ACCESS);

    apb_subsystem apb (
        .pclk(clk),
        .presetn(presetn),
        .psel(apb_psel_reg),
        .penable(apb_penable_reg),
        .pwrite(apb_pwrite_reg),
        .paddr(apb_paddr_reg),
        .pwdata(apb_pwdata_reg),
        .prdata(apb_prdata),
        .pready(apb_pready),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .gpio_oe(gpio_oe),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .cpu_irq(cpu_irq)
    );

    assign data_rdata = ram_sel ? ram_rdata : apb_prdata;

endmodule
