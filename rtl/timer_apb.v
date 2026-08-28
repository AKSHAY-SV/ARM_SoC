`timescale 1ns / 1ps

// APB3 slave: free-running down-counter timer with optional auto-reload.
// Register map (byte offset from peripheral base):
//   0x00 LOAD   - reload value (write also loads VALUE immediately)
//   0x04 VALUE  - current counter value (read-only)
//   0x08 CTRL   - bit0: enable, bit1: auto-reload
//   0x0C STATUS - bit0: interrupt pending (any write to this offset clears it)
module timer_apb (
    input wire           pclk,
    input wire           presetn,
    input wire           psel,
    input wire           penable,
    input wire           pwrite,
    input wire  [31:0]   paddr,
    input wire  [31:0]   pwdata,
    output reg  [31:0]   prdata,
    output wire          pready,
    output wire          irq
);

    localparam [7:0] REG_LOAD   = 8'h00;
    localparam [7:0] REG_VALUE  = 8'h04;
    localparam [7:0] REG_CTRL   = 8'h08;
    localparam [7:0] REG_STATUS = 8'h0C;

    localparam CTRL_EN     = 0;
    localparam CTRL_RELOAD = 1;

    reg [31:0] load_reg;
    reg [31:0] value_reg;
    reg [31:0] control_reg;
    reg [31:0] status_reg;

    assign pready = 1'b1;
    assign irq    = status_reg[0];

    wire apb_write = psel & penable & pwrite;
    wire apb_read  = psel & penable & ~pwrite;

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            load_reg    <= 32'd0;
            value_reg   <= 32'd0;
            control_reg <= 32'd0;
            status_reg  <= 32'd0;
        end else begin
            // Clear Interrupt Status Register via Register Write Address
            if (apb_write && (paddr[7:0] == REG_STATUS)) begin
                status_reg <= 32'd0;
            end

            if (apb_write) begin
                case (paddr[7:0])
                    REG_LOAD: begin
                        load_reg  <= pwdata;
                        value_reg <= pwdata;
                    end
                    REG_CTRL: begin
                        control_reg <= pwdata;
                    end
                    default: ;
                endcase
            end else if (control_reg[CTRL_EN]) begin
                if (value_reg > 0) begin
                    value_reg <= value_reg - 1;
                end else begin
                    status_reg[0] <= 1'b1;
                    if (control_reg[CTRL_RELOAD]) begin
                        value_reg <= load_reg;
                    end else begin
                        control_reg[CTRL_EN] <= 1'b0; // Clean, synchronized state termination
                    end
                end
            end
        end
    end

    always @(*) begin
        prdata = 32'd0;
        if (apb_read) begin
            case (paddr[7:0])
                REG_LOAD:   prdata = load_reg;
                REG_VALUE:  prdata = value_reg;
                REG_CTRL:   prdata = control_reg;
                REG_STATUS: prdata = status_reg;
                default:    prdata = 32'hDEADBEEF;
            endcase
        end
    end

endmodule