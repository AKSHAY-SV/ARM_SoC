// ==============================================================================
// FILE: instruction_fetch.v
// DESCRIPTION: Program Counter and Next-PC generation.
// ==============================================================================
`timescale 1ns / 1ps
`include "cpu_constants.vh"

module instruction_fetch #(
    parameter ADDR_WIDTH   = `ADDR_WIDTH,
    parameter RESET_VECTOR = 32'h0000_0000
)(
    input  wire                   clk,           
    input  wire                   reset_n,       
    input  wire                   stall,         
    input  wire                   flush,         
    input  wire [ADDR_WIDTH-1:0]  branch_target, 
    output wire [ADDR_WIDTH-1:0]  pc_current,    
    output wire [ADDR_WIDTH-1:0]  pc_next        
);
    reg  [ADDR_WIDTH-1:0] pc_reg;
    wire [ADDR_WIDTH-1:0] pc_plus_2;

    assign pc_plus_2 = pc_reg + 32'd2;
    assign pc_next = flush ? branch_target :
                     stall ? pc_reg        : pc_plus_2;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) pc_reg <= RESET_VECTOR;
        else          pc_reg <= pc_next;
    end

    assign pc_current = pc_reg;
endmodule
