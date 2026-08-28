`timescale 1ns / 1ps

// Two-flop reset synchronizer.
// Asserts sync_rstn asynchronously (immediately) but releases it
// synchronously to clk, eliminating reset-recovery/removal timing
// violations on the de-assertion edge across the design.
module reset_sync (
    input  wire clk,
    input  wire async_rst,   // active-high, asynchronous
    output wire sync_rstn    // active-low, synchronously released
);

    reg [1:0] sync_ff;

    always @(posedge clk or posedge async_rst) begin
        if (async_rst)
            sync_ff <= 2'b00;
        else
            sync_ff <= {sync_ff[0], 1'b1};
    end

    assign sync_rstn = sync_ff[1];

endmodule
