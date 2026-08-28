// ==============================================================================
// FILE: writeback_stage.v
// DESCRIPTION: Muxes the final data destined for the Register File.
// ==============================================================================
`timescale 1ns / 1ps

module writeback_stage (
    input  wire [31:0] alu_result,
    input  wire [31:0] mem_data,
    input  wire        mem_to_reg,
    output wire [31:0] wb_data
);
    assign wb_data = mem_to_reg ? mem_data : alu_result;
endmodule
