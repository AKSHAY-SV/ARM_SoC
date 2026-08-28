`timescale 1ns / 1ps

// APB3 slave: 8-bit GPIO with separate data/direction registers.
// Register map (byte offset from peripheral base):
//   0x00 DATA - write: drive value; read: live pad input level
//   0x04 DIR  - bit i: 1 = output, 0 = input
module gpio_apb (
    input wire           pclk,
    input wire           presetn,
    input wire           psel,
    input wire           penable,
    input wire           pwrite,
    input wire  [31:0]   paddr,
    input wire  [31:0]   pwdata,
    output reg  [31:0]   prdata,
    output wire          pready,

    // GDSII Compliant Split Pad Interface (Replaces problematic inout blocks)
    input  wire [7:0]    gpio_in,
    output wire [7:0]    gpio_out,
    output wire [7:0]    gpio_oe
);

    localparam [7:0] REG_DATA = 8'h00;
    localparam [7:0] REG_DIR  = 8'h04;

    reg [7:0] data_reg;
    reg [7:0] dir_reg;

    assign pready   = 1'b1;
    assign gpio_out = data_reg;
    assign gpio_oe  = dir_reg;

    wire apb_write = psel & penable & pwrite;
    wire apb_read  = psel & penable & ~pwrite;

    always @(posedge pclk or negedge presetn) begin
        if(!presetn) begin
            data_reg <= 8'h00;
            dir_reg  <= 8'h00;
        end else if(apb_write) begin
            case(paddr[7:0])
                REG_DATA: data_reg <= pwdata[7:0];
                REG_DIR:  dir_reg  <= pwdata[7:0];
                default: ;
            endcase
        end
    end

    always @(*) begin
        prdata = 32'h00000000;
        if(apb_read) begin
            case(paddr[7:0])
                REG_DATA: prdata = {24'd0, gpio_in}; // reads live pad input buffer
                REG_DIR:  prdata = {24'd0, dir_reg};
                default:  prdata = 32'hDEADBEEF;
            endcase
        end
    end

endmodule