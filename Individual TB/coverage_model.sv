`timescale 1ns / 1ps

// ============================================================================
// Functional coverage model for the SoC verification environment.
//
// Tracks hit bins across the SoC's major functional blocks and produces a
// coverage report (hit bins, coverage percentage).  Event inputs are driven
// by the testbench from transaction monitors and hierarchical peeks.
// ============================================================================
module coverage_model (
    input logic clk,
    input logic rst_n,

    // APB peripheral access events (qualified by scoreboard wires)
    input logic apb_gpio_wr, input logic apb_gpio_rd,
    input logic apb_timer_wr, input logic apb_timer_rd,
    input logic apb_spi_wr, input logic apb_spi_rd,
    input logic apb_plic_wr, input logic apb_plic_rd,
    input logic apb_uart_wr, input logic apb_uart_rd,

    // Peripheral functional events
    input logic uart_tx_byte,
    input logic uart_rx_byte,
    input logic spi_transfer_done,
    input logic timer_overflow,
    input logic timer_reload,
    input logic plic_pending_set,
    input logic plic_pending_clear,
    input logic cpu_irq_seen,

    // CPU events
    input logic cpu_load_seen,
    input logic cpu_store_seen,
    input logic cpu_branch_taken_seen,
    input logic cpu_branch_not_taken_seen,
    input logic cpu_jalr_seen,
    input logic cpu_mac_seen,
    input logic cpu_mul_seen,
    input logic cpu_div_seen,
    input logic cpu_stall_seen,

    // Negative/auxiliary events
    input logic apb_access_other,  // APB access outside the 5 known peripherals
    input logic uart_stop_err_seen // UART stop-bit error observed
);

    logic [28:0] hit_bins;   // one bit per coverage bin

    wire [28:0] bin_hits;
    int total_bins = 29;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hit_bins <= 26'd0;
        end else begin
            if (apb_gpio_wr)        hit_bins[0]  <= 1'b1;
            if (apb_gpio_rd)        hit_bins[1]  <= 1'b1;
            if (apb_timer_wr)       hit_bins[2]  <= 1'b1;
            if (apb_timer_rd)       hit_bins[3]  <= 1'b1;
            if (apb_spi_wr)         hit_bins[4]  <= 1'b1;
            if (apb_spi_rd)         hit_bins[5]  <= 1'b1;
            if (apb_plic_wr)        hit_bins[6]  <= 1'b1;
            if (apb_plic_rd)        hit_bins[7]  <= 1'b1;
            if (apb_uart_wr)        hit_bins[8]  <= 1'b1;
            if (apb_uart_rd)        hit_bins[9]  <= 1'b1;
            if (uart_tx_byte)       hit_bins[10] <= 1'b1;
            if (uart_rx_byte)       hit_bins[11] <= 1'b1;
            if (spi_transfer_done)  hit_bins[12] <= 1'b1;
            if (timer_overflow)     hit_bins[13] <= 1'b1;
            if (timer_reload)       hit_bins[14] <= 1'b1;
            if (plic_pending_set)   hit_bins[15] <= 1'b1;
            if (plic_pending_clear) hit_bins[16] <= 1'b1;
            if (cpu_irq_seen)       hit_bins[17] <= 1'b1;
            if (cpu_load_seen)      hit_bins[18] <= 1'b1;
            if (cpu_store_seen)     hit_bins[19] <= 1'b1;
            if (cpu_branch_taken_seen) hit_bins[20] <= 1'b1;
            if (cpu_jalr_seen)      hit_bins[21] <= 1'b1;
            if (cpu_mac_seen)       hit_bins[22] <= 1'b1;
            if (cpu_stall_seen)     hit_bins[23] <= 1'b1;
            if (apb_access_other)   hit_bins[24] <= 1'b1;
            if (uart_stop_err_seen) hit_bins[25] <= 1'b1;
            if (cpu_branch_not_taken_seen) hit_bins[26] <= 1'b1;
            if (cpu_mul_seen)       hit_bins[27] <= 1'b1;
            if (cpu_div_seen)       hit_bins[28] <= 1'b1;
        end
    end

    // ---- auxiliary event flags (extra bins) ----

    function automatic int hit_count();
        int n = 0;
        for (int i = 0; i < total_bins; i++)
            if (hit_bins[i]) n++;
        return n;
    endfunction

    function automatic real coverage_pct();
        return (hit_count() * 100.0) / total_bins;
    endfunction

    // Report: prints a bin-by-bin summary and the coverage percentage
    task automatic generate_report(int fd);
        $fdisplay(fd, "");
        $fdisplay(fd, "=== Functional Coverage Report ===");
        $fdisplay(fd, "APB GPIO write       : %s", hit_bins[0]  ? "hit" : "miss");
        $fdisplay(fd, "APB GPIO read        : %s", hit_bins[1]  ? "hit" : "miss");
        $fdisplay(fd, "APB TIMER write      : %s", hit_bins[2]  ? "hit" : "miss");
        $fdisplay(fd, "APB TIMER read       : %s", hit_bins[3]  ? "hit" : "miss");
        $fdisplay(fd, "APB SPI write        : %s", hit_bins[4]  ? "hit" : "miss");
        $fdisplay(fd, "APB SPI read         : %s", hit_bins[5]  ? "hit" : "miss");
        $fdisplay(fd, "APB PLIC write       : %s", hit_bins[6]  ? "hit" : "miss");
        $fdisplay(fd, "APB PLIC read        : %s", hit_bins[7]  ? "hit" : "miss");
        $fdisplay(fd, "APB UART write       : %s", hit_bins[8]  ? "hit" : "miss");
        $fdisplay(fd, "APB UART read        : %s", hit_bins[9]  ? "hit" : "miss");
        $fdisplay(fd, "UART TX byte         : %s", hit_bins[10] ? "hit" : "miss");
        $fdisplay(fd, "UART RX byte         : %s", hit_bins[11] ? "hit" : "miss");
        $fdisplay(fd, "SPI transfer         : %s", hit_bins[12] ? "hit" : "miss");
        $fdisplay(fd, "TIMER overflow       : %s", hit_bins[13] ? "hit" : "miss");
        $fdisplay(fd, "TIMER auto-reload    : %s", hit_bins[14] ? "hit" : "miss");
        $fdisplay(fd, "PLIC pending set     : %s", hit_bins[15] ? "hit" : "miss");
        $fdisplay(fd, "PLIC pending clear   : %s", hit_bins[16] ? "hit" : "miss");
        $fdisplay(fd, "PLIC cpu_irq         : %s", hit_bins[17] ? "hit" : "miss");
        $fdisplay(fd, "CPU load             : %s", hit_bins[18] ? "hit" : "miss");
        $fdisplay(fd, "CPU store            : %s", hit_bins[19] ? "hit" : "miss");
        $fdisplay(fd, "CPU branch taken     : %s", hit_bins[20] ? "hit" : "miss");
        $fdisplay(fd, "CPU jalr             : %s", hit_bins[21] ? "hit" : "miss");
        $fdisplay(fd, "CPU MAC              : %s", hit_bins[22] ? "hit" : "miss");
        $fdisplay(fd, "CPU stall (hazard)   : %s", hit_bins[23] ? "hit" : "miss");
        $fdisplay(fd, "APB out-of-window    : %s", hit_bins[24] ? "hit" : "miss");
        $fdisplay(fd, "UART stop-bit error  : %s", hit_bins[25] ? "hit" : "miss");
        $fdisplay(fd, "CPU branch not-taken : %s", hit_bins[26] ? "hit" : "miss");
        $fdisplay(fd, "CPU MUL/MULH        : %s", hit_bins[27] ? "hit" : "miss");
        $fdisplay(fd, "CPU DIV/REM          : %s", hit_bins[28] ? "hit" : "miss");
        $fdisplay(fd, "---------------------------------");
        $fdisplay(fd, "Bins hit: %0d / %0d", hit_count(), total_bins);
        $fdisplay(fd, "Coverage: %0.1f %%", coverage_pct());
        $fdisplay(fd, "=================================");

        $display("");
        $display("=== Functional Coverage: %0d/%0d hit_bins (%.1f%%) ===",
                 hit_count(), total_bins, coverage_pct());
    endtask

endmodule
