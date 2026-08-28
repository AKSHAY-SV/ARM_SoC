`timescale 1ns / 1ps

// APB3 slave: simple SPI master, fixed 8-bit shift register, MSB-first.
// Register map (byte offset from peripheral base):
//   0x00 TXDATA - byte to transmit (loaded into shift register on START)
//   0x04 RXDATA - last byte received (read-only)
//   0x08 CTRL   - bit0: START (write 1 to begin a transfer when idle)
//   0x0C STATUS - bit0: BUSY, bit1: DONE (also drives irq)
module spi_master_apb (

    input           pclk,
    input           presetn,

    input           psel,
    input           penable,
    input           pwrite,
    input  [31:0]   paddr,
    input  [31:0]   pwdata,

    output reg [31:0] prdata,
    output          pready,

    output reg      sclk,
    output          mosi,
    input           miso,
    output reg      cs_n,

    output          irq

);

    localparam [7:0] REG_TXDATA = 8'h00;
    localparam [7:0] REG_RXDATA = 8'h04;
    localparam [7:0] REG_CTRL   = 8'h08;
    localparam [7:0] REG_STATUS = 8'h0C;

    localparam STATUS_BUSY = 0;
    localparam STATUS_DONE = 1;
    localparam CTRL_START  = 0;

    localparam [3:0] SHIFT_COUNT = 4'd8; // 8-bit SPI word

    reg [7:0] txdata_reg;
    reg [7:0] rxdata_reg;
    reg [31:0] control_reg;
    reg [31:0] status_reg;

    reg [7:0] shift_tx;
    reg [7:0] shift_rx;

    reg [3:0] bit_count;
    reg busy;

    assign pready = 1'b1;

    assign irq = status_reg[STATUS_DONE];

    assign mosi = shift_tx[7];

    wire apb_write;
    wire apb_read;

    assign apb_write = psel & penable & pwrite;
    assign apb_read  = psel & penable & ~pwrite;

    always @(posedge pclk or negedge presetn)
    begin

        if(!presetn)
        begin

            txdata_reg  <= 0;
            rxdata_reg  <= 0;
            control_reg <= 0;
            status_reg  <= 0;

            shift_tx <= 0;
            shift_rx <= 0;

            bit_count <= 0;

            busy <= 0;

            sclk <= 0;
            cs_n <= 1;

        end

        else
        begin

            //-----------------------------------
            // APB WRITE
            //-----------------------------------

            if(apb_write)
            begin

                case(paddr[7:0])

                    REG_TXDATA:
                        txdata_reg <= pwdata[7:0];

                    REG_CTRL:
                    begin

                        control_reg <= pwdata;

                        if(pwdata[CTRL_START] && !busy)
                        begin

                            shift_tx <= txdata_reg;
                            shift_rx <= 8'h00;

                            bit_count <= SHIFT_COUNT;

                            busy <= 1;

                            status_reg[STATUS_BUSY] <= 1;
                            status_reg[STATUS_DONE] <= 0;

                            cs_n <= 0;

                        end

                    end

                    // Write-1-to-clear for the DONE flag (interrupt status).
                    // Without this the DONE bit is sticky until the next
                    // transfer, which holds spi_irq (and the PLIC's SPI
                    // pending bit) asserted forever.
                    REG_STATUS:
                        if(pwdata[STATUS_DONE])
                            status_reg[STATUS_DONE] <= 1'b0;

                    default: ;

                endcase

            end

            //-----------------------------------
            // SPI SHIFT ENGINE
            //-----------------------------------

            if(busy)
            begin

                sclk <= ~sclk;

                if(sclk == 0)
                begin

                    shift_rx <= {shift_rx[6:0], miso};
                    shift_tx <= {shift_tx[6:0], 1'b0};

                    bit_count <= bit_count - 1;

                    if(bit_count == 1)
                    begin

                        busy <= 0;

                        cs_n <= 1;

                        sclk <= 0;

                        rxdata_reg <= {shift_rx[6:0], miso};

                        status_reg[STATUS_BUSY] <= 0;
                        status_reg[STATUS_DONE] <= 1;

                    end

                end

            end

        end

    end

    always @(*)
    begin

        prdata = 32'h0;

        if(apb_read)
        begin

            case(paddr[7:0])

                REG_TXDATA: prdata = {24'd0, txdata_reg};
                REG_RXDATA: prdata = {24'd0, rxdata_reg};
                REG_CTRL:   prdata = control_reg;
                REG_STATUS: prdata = status_reg;

                default:
                    prdata = 32'hDEADBEEF;

            endcase

        end

    end

endmodule