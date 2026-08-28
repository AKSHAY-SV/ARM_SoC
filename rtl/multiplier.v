// ==============================================================================
// FILE: multiplier.v
// DESCRIPTION: 32-bit hardware multiplier and accumulate unit.
// ==============================================================================

`timescale 1ns / 1ps
`include "cpu_constants.vh"

module multiplier #(
    parameter DATA_WIDTH = `DATA_WIDTH
)(
    input  wire [DATA_WIDTH-1:0] op_a,
    input  wire [DATA_WIDTH-1:0] op_b,
    input  wire [DATA_WIDTH-1:0] accumulate_val,
    input  wire                  mac_enable,
    
    output wire [DATA_WIDTH-1:0] result
);

    // Standard 32x32 -> 64 multiplier. We only keep the lower 32 bits 
    // for standard Cortex-M0/M3 Thumb MUL operations.
    wire [63:0] full_product = op_a * op_b;
    
    assign result = mac_enable ? (full_product[31:0] + accumulate_val) : full_product[31:0];

endmodule
