// ==============================================================================
// FILE: memory_interface.v
// DESCRIPTION: CPU-to-Bus abstraction wrapper. 
// ==============================================================================
`timescale 1ns / 1ps

module memory_interface (
    input  wire        clk,
    input  wire        reset_n,
    
    // Core side
    input  wire [31:0] core_addr,
    input  wire [31:0] core_wdata,
    input  wire        core_we,
    input  wire        core_req,
    output wire [31:0] core_rdata,
    output wire        core_ready,
    
    // AHB Master Side
    output wire [31:0] ahb_req_addr,
    output wire [31:0] ahb_req_wdata,
    output wire        ahb_req_we,
    output wire        ahb_req_valid,
    input  wire [31:0] ahb_rdata,
    input  wire        ahb_ready
);

    assign ahb_req_addr  = core_addr;
    assign ahb_req_wdata = core_wdata;
    assign ahb_req_we    = core_we;
    assign ahb_req_valid = core_req;
    
    assign core_rdata    = ahb_rdata;
    assign core_ready    = ahb_ready;

endmodule
