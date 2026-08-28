// ==============================================================================
// FILE: bus_controller.v
// DESCRIPTION: Arbitrates Unified Bus access. Priority is given to Data Load/Stores
//              over Instruction Fetches to prevent data hazards.
// ==============================================================================

`timescale 1ns / 1ps
`include "cpu_constants.vh"

module bus_controller (
    input  wire        clk,
    input  wire        reset_n,
    
    // IF Request
    input  wire [31:0] if_addr,
    input  wire        if_req,
    output wire        if_grant,
    
    // Data Request (MEM Stage)
    input  wire [31:0] data_addr,
    input  wire        data_req,
    input  wire        data_write,
    output wire        data_grant,
    
    // To AHB Master
    output wire [31:0] ahb_addr,
    output wire        ahb_req,
    output wire        ahb_write
);

    // Priority logic: Data access always wins arbitration over instruction fetch
    assign data_grant = data_req;
    assign if_grant   = if_req & ~data_req;
    
    assign ahb_req    = data_req | if_req;
    assign ahb_addr   = data_grant ? data_addr : if_addr;
    assign ahb_write  = data_grant ? data_write : 1'b0;

endmodule

