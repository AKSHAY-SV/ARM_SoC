`timescale 1ns / 1ps

module uart_rx(

    input wire clk,
    input wire rst,

    input wire baud_tick,

    input wire rx,

    output reg [7:0] rx_data,
    output reg rx_valid

);

localparam IDLE  = 2'b00;
localparam START = 2'b01;
localparam DATA  = 2'b10;
localparam STOP  = 2'b11;

reg [1:0] state;

reg [2:0] bit_count;
reg [7:0] shift_reg;

always @(posedge clk or posedge rst)
begin

    if(rst)
    begin
        state     <= IDLE;
        bit_count <= 3'd0;
        shift_reg <= 8'd0;
        rx_data   <= 8'd0;
        rx_valid  <= 1'b0;
    end

    else
    begin

        rx_valid <= 1'b0;

        case(state)

        IDLE:
        begin
            if(rx == 1'b0)
                state <= START;
        end

        START:
        begin
            if(baud_tick)
            begin
                bit_count <= 3'd0;
                state     <= DATA;
            end
        end

        DATA:
        begin
            if(baud_tick)
            begin

                shift_reg[bit_count] <= rx;

                if(bit_count == 3'd7)
                    state <= STOP;
                else
                    bit_count <= bit_count + 1'b1;

            end
        end

        STOP:
        begin
            if(baud_tick)
            begin

                rx_data  <= shift_reg;
                rx_valid <= 1'b1;

                state <= IDLE;
            end
        end

        endcase

    end

end

endmodule
