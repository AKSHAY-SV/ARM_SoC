`timescale 1ns / 1ps

module uart_regs(

    input wire clk,
    input wire rst,

    input wire wr_en,
    input wire rd_en,

    input wire [3:0] addr,
    input wire [31:0] wdata,

    output reg [31:0] rdata,

    input wire [7:0] rx_data,
    input wire rx_valid,
    input wire tx_busy,

    output reg [7:0] tx_data,
    output reg tx_start,

    output reg [15:0] baud_div

);

reg [31:0] status_reg;

always @(posedge clk or posedge rst)
begin

    if(rst)
    begin
        tx_data  <= 8'd0;
        tx_start <= 1'b0;
        baud_div <= 16'd10;
    end

    else
    begin

        tx_start <= 1'b0;

        if(wr_en)
        begin

            case(addr)

            4'h0:
            begin
                tx_data  <= wdata[7:0];
                tx_start <= 1'b1;
            end

            4'h4:
            begin
                baud_div <= wdata[15:0];
            end

            endcase

        end

    end

end

always @(*)
begin

    status_reg = 32'd0;

    status_reg[0] = tx_busy;
    status_reg[1] = rx_valid;

    case(addr)

    4'h0: rdata = {24'd0, rx_data};

    4'h8: rdata = status_reg;

    4'h4: rdata = {16'd0, baud_div};

    default:
        rdata = 32'd0;

    endcase

end

endmodule
