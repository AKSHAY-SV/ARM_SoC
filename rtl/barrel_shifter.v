// ==============================================================================
// FILE: barrel_shifter.v
// DESCRIPTION: ARM Barrel Shifter supporting LSL, LSR, ASR, ROR.
// ==============================================================================

`timescale 1ns / 1ps
`include "cpu_constants.vh"

module barrel_shifter #(
    parameter DATA_WIDTH = `DATA_WIDTH
)(
    input  wire [4:0]            shift_type, // Reuses ALU ops (LSL, LSR, ASR, ROR)
    input  wire [DATA_WIDTH-1:0] data_in,
    input  wire [4:0]            shift_amt,
    
    output reg  [DATA_WIDTH-1:0] data_out,
    output reg                   carry_out
);

    always @(*) begin
        carry_out = 1'b0;
        if (shift_amt == 5'h0) begin
            data_out = data_in;
        end else begin
            case (shift_type)
                `ALU_LSL: begin
                    data_out  = data_in << shift_amt;
                    carry_out = data_in[32 - shift_amt];
                end
                `ALU_LSR: begin
                    data_out  = data_in >> shift_amt;
                    carry_out = data_in[shift_amt - 1];
                end
                `ALU_ASR: begin
                    data_out  = $signed(data_in) >>> shift_amt;
                    carry_out = data_in[shift_amt - 1];
                end
                `ALU_ROR: begin
                    data_out  = (data_in >> shift_amt) | (data_in << (32 - shift_amt));
                    carry_out = data_in[shift_amt - 1];
                end
                default: data_out = data_in;
            endcase
        end
    end

endmodule
