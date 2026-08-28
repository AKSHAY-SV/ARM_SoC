`timescale 1ns / 1ps

// ============================================================================
// SPI BFM for the SoC testbench - MONITOR mode.
//
// The SoC's SPI master pins (sclk/mosi/cs_n) are not exposed at the chip
// boundary, so this BFM observes them through hierarchical references and
// validates the master's behavior:
//   - CS falling edge marks transfer start (MOSI = TXDATA[7] at that point)
//   - each SCLK falling edge carries the next MOSI bit (the master shifts on
//     rising edges, so MOSI is stable during the following low phase)
//   - 8 bits captured per transfer, MSB first
//   - protocol statistics: CS-low duration, SCLK toggle count
//
// A passive MISO drive is provided for a future slave-responder use case;
// in this environment the DUT ties MISO to 0, so it stays undriven.
// ============================================================================
module spi_bfm #(
    parameter int MAX_TRANSFERS = 8
)(
    input  logic pclk,
    input  logic presetn,

    // DUT SPI master lines (hierarchical refs in the testbench)
    input  logic sclk,
    input  logic mosi,
    output logic miso,
    input  logic cs_n,

    // Expected MOSI bytes; checked as transfers complete
    input  logic [7:0] expected_data [0:MAX_TRANSFERS-1],
    input  logic       expect_en,

    // Monitor outputs
    output logic [7:0] rx_data,
    output logic       rx_valid,
    output logic       transfer_done,
    output logic [3:0] transfer_count,
    output logic       data_match_ok,

    // Protocol statistics
    output logic [15:0] last_cs_low_cycles,
    output logic [15:0] last_sclk_edges,
    output logic        cs_ok,
    output logic        sclk_ok
);

    logic cs_prev;
    logic sclk_prev;

    typedef enum logic [1:0] {
        S_IDLE = 2'd0,
        S_SHIFT = 2'd1,
        S_DONE  = 2'd2
    } state_t;

    state_t state;
    logic [3:0] bit_idx;          // next bit to capture (7..0)
    logic [7:0] shift_rx;
    logic [15:0] cs_low_cnt;      // cycles CS low
    logic [15:0] sclk_edge_cnt;   // SCLK transitions while CS low
    logic [3:0]  txn_count;
    logic [3:0]  checked;
    logic [3:0]  mismatches;
    logic        done_flag;

    assign transfer_done = done_flag;
    assign transfer_count = txn_count;
    assign data_match_ok = (mismatches == 4'd0) && (checked > 0);
    // The DUT holds CS low for 15 clocks and toggles SCLK 15 times per
    // transfer; allow monitor pipeline latency.
    assign cs_ok = !(cs_low_cnt > 0 && (cs_low_cnt < 14 || cs_low_cnt > 16));
    assign sclk_ok = !(sclk_edge_cnt > 0 && (sclk_edge_cnt < 12 || sclk_edge_cnt > 16));

    always_ff @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            state       <= S_IDLE;
            cs_prev     <= 1'b1;
            sclk_prev   <= 1'b0;
            bit_idx     <= 4'd7;
            shift_rx    <= 8'h00;
            rx_data     <= 8'h00;
            rx_valid    <= 1'b0;
            done_flag   <= 1'b0;
            cs_low_cnt  <= 16'd0;
            sclk_edge_cnt <= 16'd0;
            txn_count   <= 4'd0;
            checked     <= 4'd0;
            mismatches  <= 4'd0;
            miso        <= 1'b1;
        end else begin
            rx_valid  <= 1'b0;
            done_flag <= 1'b0;
            cs_prev   <= cs_n;
            sclk_prev <= sclk;

            case (state)
                S_IDLE: begin
                    if (cs_prev && !cs_n) begin
                        // Transfer start: MOSI holds TXDATA[7]
                        shift_rx[7] <= mosi;
                        bit_idx     <= 4'd6;
                        cs_low_cnt  <= 16'd1;
                        sclk_edge_cnt <= 16'd0;
                        state       <= S_SHIFT;
                    end
                end

                S_SHIFT: begin
                    if (!cs_n) begin
                        cs_low_cnt <= cs_low_cnt + 1;
                        // Any SCLK edge while CS low: count it
                        if (sclk_prev != sclk) begin
                            sclk_edge_cnt <= sclk_edge_cnt + 1;
                        end
                        // SCLK falling edge: capture next MOSI bit
                        if (sclk_prev && !sclk) begin
                            shift_rx[bit_idx] <= mosi;
                            if (bit_idx == 4'd0) begin
                                rx_data  <= {shift_rx[7:1], mosi};
                                rx_valid <= 1'b1;
                                state    <= S_DONE;
                            end else begin
                                bit_idx <= bit_idx - 1;
                            end
                        end
                    end
                end

                S_DONE: begin
                    if (cs_n) begin
                        // Transfer finished: protocol checks + compare
                        if (cs_low_cnt < 14 || cs_low_cnt > 16) begin
                            $error("SPI BFM: CS low for %0d cycles (expected ~15)", cs_low_cnt);
                        end
                        if (sclk_edge_cnt < 12 || sclk_edge_cnt > 16) begin
                            $error("SPI BFM: SCLK had %0d edges (expected ~15)", sclk_edge_cnt);
                        end
                        txn_count <= txn_count + 1;
                        if (expect_en) begin
                            if (checked < MAX_TRANSFERS) begin
                                if (rx_data !== expected_data[checked]) begin
                                    $error("SPI BFM: MOSI byte mismatch: expected 0x%02X, got 0x%02X",
                                           expected_data[checked], rx_data);
                                    mismatches <= mismatches + 1;
                                end
                                checked <= checked + 1;
                            end
                        end
                        done_flag <= 1'b1;
                        state     <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
