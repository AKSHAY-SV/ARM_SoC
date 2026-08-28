// ==============================================================================
// FILE: execute_stage.v
// DESCRIPTION: Execution wrapper combining ALU, Multiplier, and Shifter.
// ==============================================================================
`timescale 1ns / 1ps
`include "cpu_constants.vh"

module execute_stage (
    input  wire [4:0]  alu_op,
    input  wire [31:0] op_a,
    input  wire [31:0] op_b,
    input  wire        carry_in,
    output reg  [31:0] result,
    output wire        flag_n,
    output wire        flag_z,
    output wire        flag_c,
    output wire        flag_v
);
    wire [63:0] mul_res = op_a * op_b;
    wire [32:0] add_res = {1'b0, op_a} + {1'b0, op_b};
    wire [32:0] sub_res = {1'b0, op_a} - {1'b0, op_b};

    always @(*) begin
        case (alu_op)
            `ALU_ADD: result = add_res[31:0];
            `ALU_SUB: result = sub_res[31:0];
            `ALU_AND: result = op_a & op_b;
            `ALU_ORR: result = op_a | op_b;
            `ALU_EOR: result = op_a ^ op_b;
            `ALU_LSL: result = op_a << op_b[4:0];
            `ALU_LSR: result = op_a >> op_b[4:0];
            `ALU_ASR: result = $signed(op_a) >>> op_b[4:0];
            `ALU_MUL: result = mul_res[31:0];
            default:  result = op_a;
        endcase
    end

    assign flag_n = result[31];
    assign flag_z = (result == 32'h0);
    assign flag_c = (alu_op == `ALU_ADD) ? add_res[32] : (alu_op == `ALU_SUB) ? ~sub_res[32] : 1'b0;
    assign flag_v = 1'b0; 
endmodule
