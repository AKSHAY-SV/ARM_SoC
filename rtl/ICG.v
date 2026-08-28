`timescale 1ns / 1ps
module ICG (
    input wire clk_in,
    input wire enable,
    output wire clk_out
);
reg enable_latch;
always @(clk_in or enable) begin
    if(!clk_in) enable_latch <= enable;
end
assign clk_out = clk_in & enable_latch;
endmodule
