// ==============================================================================
// FILE: ahb_master.v
// DESCRIPTION: Clean AMBA 3 AHB-Lite Master Interface.
// ==============================================================================
`timescale 1ns / 1ps
`include "cpu_constants.vh"

module ahb_master (
    input  wire        clk,
    input  wire        reset_n,
    input  wire [31:0] req_addr,
    input  wire [31:0] req_wdata,
    input  wire        req_write,
    input  wire        req_valid,
    output wire [31:0] req_rdata,
    output wire        req_ready,
    output reg  [31:0] HADDR,
    output reg  [1:0]  HTRANS,
    output reg         HWRITE,
    output wire [2:0]  HSIZE,
    output reg  [31:0] HWDATA,
    input  wire [31:0] HRDATA,
    input  wire        HREADY
);
    assign HSIZE = `HSIZE_WORD;
    assign req_rdata = HRDATA;
    assign req_ready = HREADY;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            HTRANS <= `HTRANS_IDLE;
            HADDR  <= 32'h0;
            HWRITE <= 1'b0;
        end else if (HREADY) begin
            if (req_valid) begin
                HTRANS <= `HTRANS_NONSEQ;
                HADDR  <= req_addr;
                HWRITE <= req_write;
                HWDATA <= req_wdata; 
            end else begin
                HTRANS <= `HTRANS_IDLE;
            end
        end
    end
endmodule
