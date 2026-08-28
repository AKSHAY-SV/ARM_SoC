`timescale 1ns / 1ps

// APB3 slave: minimal PLIC-style interrupt aggregator, 4 fixed sources.
// Register map (byte offset from peripheral base):
//   0x00 PENDING - bit i: source i pending (write 1 to clear)
//   0x04 ENABLE  - bit i: source i enabled to drive cpu_irq
// Source map: bit0=timer, bit1=spi, bit2=gpio, bit3=uart
module plic_simple (

    input           pclk,
    input           presetn,

    // APB Interface
    input           psel,
    input           penable,
    input           pwrite,
    input  [31:0]   paddr,
    input  [31:0]   pwdata,

    output reg [31:0] prdata,
    output          pready,

    // Interrupt Sources
    input           timer_irq,
    input           spi_irq,
    input           gpio_irq,
    input           uart_irq,

    // CPU Interrupt
    output          cpu_irq

);

    localparam [7:0] REG_PENDING = 8'h00;
    localparam [7:0] REG_ENABLE  = 8'h04;

    localparam SRC_TIMER = 0;
    localparam SRC_SPI   = 1;
    localparam SRC_GPIO  = 2;
    localparam SRC_UART  = 3;

    reg [3:0] pending_reg;
    reg [3:0] enable_reg;

    assign pready = 1'b1;

    wire apb_write;
    wire apb_read;

    assign apb_write = psel & penable & pwrite;
    assign apb_read  = psel & penable & (~pwrite);

    assign cpu_irq = |(pending_reg & enable_reg);

    always @(posedge pclk or negedge presetn)
    begin
        if(!presetn)
        begin
            pending_reg <= 4'b0000;
            enable_reg  <= 4'b0000;
        end
        else
        begin

            //----------------------------------
            // Capture Interrupt Sources
            //----------------------------------

            if(timer_irq)
                pending_reg[SRC_TIMER] <= 1'b1;

            if(spi_irq)
                pending_reg[SRC_SPI] <= 1'b1;

            if(gpio_irq)
                pending_reg[SRC_GPIO] <= 1'b1;

            if(uart_irq)
                pending_reg[SRC_UART] <= 1'b1;

            //----------------------------------
            // APB Writes
            //----------------------------------

            if(apb_write)
            begin

                case(paddr[7:0])

                    // ENABLE REGISTER
                    REG_ENABLE:
                        enable_reg <= pwdata[3:0];

                    // CLEAR PENDING BITS
                    REG_PENDING:
                        pending_reg <= pending_reg & ~pwdata[3:0];

                    default: ;

                endcase

            end

        end
    end

    always @(*)
    begin

        prdata = 32'h00000000;

        if(apb_read)
        begin

            case(paddr[7:0])

                REG_PENDING:
                    prdata = {28'd0,pending_reg};

                REG_ENABLE:
                    prdata = {28'd0,enable_reg};

                default:
                    prdata = 32'hDEADBEEF;

            endcase

        end

    end

endmodule