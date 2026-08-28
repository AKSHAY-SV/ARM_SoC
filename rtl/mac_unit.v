`timescale 1ns / 1ps
module mac_unit (
    input  wire        clk,
    input  wire        rst,
    input  wire        mac_en,   
    input  wire        mac_clr,     
    input  wire [31:0] mac_in,      
    output reg  [31:0] acc          
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            acc <= 32'h00000000;
        else if (mac_clr)
            acc <= 32'h00000000;
        else if (mac_en)
            acc <= mac_in;          
    end
endmodule
