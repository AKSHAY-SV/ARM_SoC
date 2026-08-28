`timescale 1ns/1ps

module pc (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] pc_next,
    output reg  [31:0] pc_out
);

    // NOTE: a hand-instantiated CLKBUF primitive was previously placed on
    // this clock net inside RTL. Removed — clock buffering is a physical-
    // design/CTS concern, not an RTL concern; behavior is unchanged since
    // the buffer was a pure pass-through.
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_out <= 32'h00000000;
        else
            pc_out <= pc_next;
    end
endmodule