// ==============================================================================
// FILE: address_decoder.v
// DESCRIPTION: Generates chip selects based on the active AHB address phase.
// ==============================================================================

`timescale 1ns / 1ps
`include "cpu_constants.vh"

module address_decoder (
    input  wire [31:0] haddr,
    
    output wire        cs_rom,
    output wire        cs_ram,
    output wire        cs_apb_bridge
);

    // Standardized memory boundaries
    localparam ROM_BASE = 32'h0000_0000;
    localparam RAM_BASE = 32'h2000_0000; // Standard Cortex-M SRAM region
    localparam APB_BASE = 32'h4000_0000; // Standard Cortex-M Peripheral region

    assign cs_rom        = (haddr[31:28] == ROM_BASE[31:28]);
    assign cs_ram        = (haddr[31:28] == RAM_BASE[31:28]);
    assign cs_apb_bridge = (haddr[31:28] == APB_BASE[31:28]);

endmodule
