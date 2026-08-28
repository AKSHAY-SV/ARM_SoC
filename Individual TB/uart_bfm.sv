`timescale 1ns / 1ps

// ============================================================================
// UART BFM for the SoC testbench.
//
// Matches the SoC's UART exactly: fixed baud divider of 10 (one bit period =
// CLKS_PER_BIT clock cycles), frame = start + 8 data bits (LSB first) + stop.
//
// TX side (drives the DUT's uart_rx): bit transitions are aligned to the
// DUT's internal baud tick (fed in via the `baud_tick` port from a
// hierarchical reference) with a 2-cycle guard, so the DUT, which samples at
// baud-tick edges, always sees a stable bit value.
//
// RX side (monitors the DUT's uart_tx): detects the start-bit falling edge
// and samples each bit at its midpoint, giving robust reception regardless
// of baud-tick phase.
// ============================================================================
module uart_bfm #(
    parameter int CLKS_PER_BIT = 10
)(
    input  logic clk,
    input  logic rst_n,
    input  logic baud_tick,   // DUT internal baud tick (hierarchical ref)

    // UART lines: tx_line drives DUT RX, rx_line samples DUT TX
    output logic tx_line,
    input  logic rx_line,

    // TX control (pulse tx_start to send one byte)
    input  logic tx_start,
    input  logic [7:0] tx_data,
    input  logic tx_bad_stop,   // drive a LOW stop bit on this frame
    output logic tx_done,
    output logic stop_bit_injected, // pulsed when a bad-stop frame was sent

    // RX output (rx_valid pulses when a byte completes)
    output logic [7:0] rx_data,
    output logic rx_valid,
    output logic stop_bit_error
);

    // ------------------------------------------------------------------
    // TX state machine
    // ------------------------------------------------------------------
    typedef enum logic [2:0] {
        TX_IDLE  = 3'd0,
        TX_WAIT  = 3'd1,   // waiting for next baud tick
        TX_START = 3'd2,   // driving start bit
        TX_DATA  = 3'd3,   // driving data bits
        TX_STOP  = 3'd4    // driving stop bit
    } tx_state_t;

    tx_state_t tx_state;
    logic [3:0] tx_bit_idx;
    logic [7:0] tx_shift;
    logic [7:0] tx_cnt;
    logic tx_stop_val;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state  <= TX_IDLE;
            tx_line   <= 1'b1;
            tx_done   <= 1'b0;
            stop_bit_injected <= 1'b0;
            tx_shift  <= 8'h00;
            tx_bit_idx<= 4'd0;
            tx_cnt    <= 8'd0;
            tx_stop_val <= 1'b1;
        end else begin
            tx_done <= 1'b0;
            stop_bit_injected <= 1'b0;
            case (tx_state)
                TX_IDLE: begin
                    tx_line <= 1'b1;
                    if (tx_start) begin
                        tx_shift <= tx_data;
                        tx_stop_val <= tx_bad_stop;
                        tx_state <= TX_WAIT;
                    end
                end
                // Align start bit to a baud tick, then drive low 2 cycles
                // after the tick (DUT samples at tick+1: sees stable level).
                TX_WAIT: begin
                    if (baud_tick) begin
                        // Start bit just after the tick; hold it long enough
                        // that the DUT's first DATA sample (tick+20, see
                        // below) lands mid-bit of data bit 0.
                        tx_line  <= 1'b0;
                        tx_cnt   <= CLKS_PER_BIT + 3;
                        tx_state <= TX_START;
                    end
                end
                TX_START: begin
                    if (tx_cnt == 0) begin
                        tx_line  <= tx_shift[0];
                        tx_bit_idx <= 4'd1;
                        tx_cnt   <= CLKS_PER_BIT - 1;
                        tx_state <= TX_DATA;
                    end else begin
                        tx_cnt <= tx_cnt - 1;
                    end
                end
                TX_DATA: begin
                    if (tx_cnt == 0) begin
                        if (tx_bit_idx == 4'd8) begin
                            tx_line  <= tx_stop_val ? 1'b0 : 1'b1;
                            tx_cnt   <= CLKS_PER_BIT - 1;
                            tx_state <= TX_STOP;
                        end else begin
                            tx_line    <= tx_shift[tx_bit_idx];
                            tx_bit_idx <= tx_bit_idx + 1;
                            tx_cnt     <= CLKS_PER_BIT - 1;
                        end
                    end else begin
                        tx_cnt <= tx_cnt - 1;
                    end
                end
                TX_STOP: begin
                    if (tx_cnt == 0) begin
                        tx_state <= TX_IDLE;
                        tx_done  <= 1'b1;
                        stop_bit_injected <= tx_stop_val;
                    end else begin
                        tx_cnt <= tx_cnt - 1;
                    end
                end
                default: tx_state <= TX_IDLE;
            endcase
        end
    end

    // ------------------------------------------------------------------
    // RX monitor: start-bit edge detect, then mid-bit sampling
    // ------------------------------------------------------------------
    typedef enum logic [2:0] {
        RX_IDLE = 3'd0,
        RX_WAIT = 3'd1,   // waiting for first bit sample point
        RX_BITS = 3'd2,   // sampling 8 data bits
        RX_STOP = 3'd3    // sampling stop bit
    } rx_state_t;

    rx_state_t rx_state;
    logic rx_prev;
    logic [3:0] rx_bit_idx;
    logic [7:0] rx_shift;
    logic [7:0] rx_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state       <= RX_IDLE;
            rx_prev        <= 1'b1;
            rx_bit_idx     <= 4'd0;
            rx_shift       <= 8'h00;
            rx_cnt         <= 8'd0;
            rx_data        <= 8'h00;
            rx_valid       <= 1'b0;
            stop_bit_error <= 1'b0;
        end else begin
            rx_valid <= 1'b0;
            rx_prev  <= rx_line;

            case (rx_state)
                RX_IDLE: begin
                    if (rx_prev && !rx_line) begin
                        rx_cnt   <= 8'd0;
                        rx_state <= RX_WAIT;
                    end
                end
                // First data-bit sample is 14 cycles after the detected
                // falling edge (midpoint of bit 0), then every 10 cycles.
                RX_WAIT: begin
                    if (rx_cnt == 8'd14) begin
                        rx_shift[0] <= rx_line;
                        rx_bit_idx  <= 4'd1;
                        rx_cnt      <= 8'd0;
                        rx_state    <= RX_BITS;
                    end else begin
                        rx_cnt <= rx_cnt + 1;
                    end
                end
                RX_BITS: begin
                    if (rx_cnt == CLKS_PER_BIT - 1) begin
                        rx_cnt <= 8'd0;
                        rx_shift[rx_bit_idx] <= rx_line;
                        if (rx_bit_idx == 4'd7) begin
                            rx_state <= RX_STOP;
                        end else begin
                            rx_bit_idx <= rx_bit_idx + 1;
                        end
                    end else begin
                        rx_cnt <= rx_cnt + 1;
                    end
                end
                RX_STOP: begin
                    if (rx_cnt == CLKS_PER_BIT - 1) begin
                        rx_data        <= rx_shift;
                        rx_valid       <= 1'b1;
                        stop_bit_error <= ~rx_line;
                        rx_state       <= RX_IDLE;
                    end else begin
                        rx_cnt <= rx_cnt + 1;
                    end
                end
                default: rx_state <= RX_IDLE;
            endcase
        end
    end

endmodule
