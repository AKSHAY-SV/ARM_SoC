`timescale 1ns / 1ps

module baud_gen(

    input wire clk,
    input wire rst,

    input wire [15:0] baud_div,

    output reg baud_tick

);

reg [15:0] counter;

always @(posedge clk or posedge rst)
begin

    if(rst)
    begin
        counter   <= 16'd0;
        baud_tick <= 1'b0;
    end

    else
    begin

        if(counter == baud_div - 1)
        begin
            counter   <= 16'd0;
            baud_tick <= 1'b1;
        end

        else
        begin
            counter   <= counter + 1'b1;
            baud_tick <= 1'b0;
        end

    end

end

endmodule
