// ==============================================================================
// FILE: alu.v
// DESCRIPTION: RV32IM combinational ALU. Implements base integer ops plus
//              M-extension multiply/divide/remainder, and a MAC passthrough
//              slot (5'b10011) used by the OP_CUSTOM MAC instruction.
// ==============================================================================
`timescale 1ns / 1ps

module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [31:0] acc,
    input  wire [4:0]  alu_ctrl,
    output reg  [31:0] result,
    output wire        zero
);
    wire signed [31:0] sa = $signed(a);
    wire signed [31:0] sb = $signed(b);

    wire signed [63:0] mul_ss   = sa * sb;
    wire        [63:0] mul_uu   = a  * b;
    wire signed [63:0] mul_su   = $signed(a) * $signed({1'b0, b});
    wire signed [63:0] mac_full = sa * sb + $signed(acc);

    always @(*) begin
        case (alu_ctrl)
            5'b00000: result = a + b;
            5'b00001: result = a - b;
            5'b00010: result = a & b;
            5'b00011: result = a | b;
            5'b00100: result = a ^ b;
            5'b00101: result = a << b[4:0];
            5'b00110: result = a >> b[4:0];
            5'b00111: result = $signed(sa) >>> b[4:0];
            5'b01000: result = (sa < sb) ? 32'd1 : 32'd0;
            5'b01001: result = (a  < b)  ? 32'd1 : 32'd0;
            5'b01010: result = b;

            5'b01011: result = mul_ss[31:0];
            5'b01100: result = mul_ss[63:32];
            5'b01101: result = mul_uu[63:32];
            5'b01110: result = mul_su[63:32];
            5'b01111: result = (sb == 0) ? 32'hFFFFFFFF
                               : (sa == -32'sd2147483648 && sb == -32'sd1) ? 32'h80000000
                               : $signed(sa / sb);
            5'b10000: result = (b == 0) ? 32'hFFFFFFFF : a / b;
            5'b10001: result = (sb == 0) ? a
                               : (sa == -32'sd2147483648 && sb == -32'sd1) ? 32'd0
                               : $signed(sa % sb);
            5'b10010: result = (b == 0) ? a : a % b;

            5'b10011: result = mac_full[31:0];

            default:  result = 32'hDEADBEEF;
        endcase
    end

    assign zero = (result == 32'h00000000);
endmodule
