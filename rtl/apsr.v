// ==============================================================================
// FILE: apsr.v
// DESCRIPTION: Application Program Status Register. Holds N, Z, C, V flags.
// ==============================================================================

`timescale 1ns / 1ps

module apsr (
    input  wire clk,
    input  wire reset_n,
    
    input  wire update_n,
    input  wire update_z,
    input  wire update_c,
    input  wire update_v,
    
    input  wire next_n,
    input  wire next_z,
    input  wire next_c,
    input  wire next_v,
    
    output reg  flag_n,
    output reg  flag_z,
    output reg  flag_c,
    output reg  flag_v
);

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            flag_n <= 1'b0;
            flag_z <= 1'b0;
            flag_c <= 1'b0;
            flag_v <= 1'b0;
        end else begin
            if (update_n) flag_n <= next_n;
            if (update_z) flag_z <= next_z;
            if (update_c) flag_c <= next_c;
            if (update_v) flag_v <= next_v;
        end
    end

endmodule
