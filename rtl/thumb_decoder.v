// ==============================================================================
// FILE: thumb_decoder.v
// DESCRIPTION: Decodes 16-bit ARM Thumb instructions.
// ==============================================================================
`timescale 1ns / 1ps
`include "cpu_constants.vh"

module thumb_decoder (
    input  wire [15:0] instr,
    output reg  [4:0]  alu_op,
    output reg  [3:0]  cond_code,
    output wire [3:0]  rn,
    output wire [3:0]  rm,
    output wire [3:0]  rd,
    output reg  [31:0] imm_val,
    output reg         is_dp,
    output reg         is_load,
    output reg         is_store,
    output reg         is_branch
);
    assign rm = {1'b0, instr[5:3]};
    assign rn = {1'b0, instr[2:0]};
    assign rd = {1'b0, instr[2:0]}; 

    always @(*) begin
        alu_op    = `ALU_MOV;
        cond_code = `COND_AL;
        imm_val   = 32'h0;
        is_dp = 0; is_load = 0; is_store = 0; is_branch = 0;

        if (instr[15:10] == 6'b010000) begin
            is_dp = 1;
            case (instr[9:6])
                4'b0000: alu_op = `ALU_AND;
                4'b0001: alu_op = `ALU_EOR;
                4'b0010: alu_op = `ALU_LSL;
                4'b0101: alu_op = `ALU_ADC;
                4'b1101: alu_op = `ALU_ORR;
                default: alu_op = `ALU_ADD;
            endcase
        end 
        else if (instr[15:12] == 4'b0101) begin
            if (instr[11]) is_load = 1; else is_store = 1;
            alu_op = `ALU_ADD;
        end
        else if (instr[15:12] == 4'b1101) begin
            is_branch = 1;
            cond_code = instr[11:8];
            imm_val = {{23{instr[7]}}, instr[7:0], 1'b0};
        end
    end
endmodule
