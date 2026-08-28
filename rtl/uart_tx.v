`timescale 1ns / 1ps

module uart_tx(

    input wire clk,
    input wire rst,

    input wire baud_tick,

    input wire tx_start,
    input wire [7:0] tx_data,

    output reg tx,
    output reg busy

);

localparam IDLE  = 2'b00;
localparam START = 2'b01;
localparam DATA  = 2'b10;
localparam STOP  = 2'b11;

reg [1:0] state;

reg [7:0] shift_reg;
reg [2:0] bit_count;

always @(posedge clk or posedge rst)
begin

    if(rst)
    begin
        state     <= IDLE;
        tx        <= 1'b1;
        busy      <= 1'b0;
        shift_reg <= 8'b0;
        bit_count <= 3'b0;
    end

    else
    begin

        case(state)

        IDLE:
        begin
            tx   <= 1'b1;
            busy <= 1'b0;

            if(tx_start)
            begin
                shift_reg <= tx_data;
                bit_count <= 3'd0;
                busy      <= 1'b1;
                state     <= START;
            end
        end

        START:
        begin
            if(baud_tick)
            begin
                tx    <= 1'b0;
                state <= DATA;
            end
        end

        DATA:
        begin
            if(baud_tick)
            begin

                tx <= shift_reg[0];

                shift_reg <= shift_reg >> 1;

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
                tx    <= 1'b1;
                busy  <= 1'b0;
                state <= IDLE;
            end
        end

        endcase

    end

end

endmodule
