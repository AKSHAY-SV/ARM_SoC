`timescale 1ns / 1ps

// Boot instruction memory. Content is loaded from BOOT_HEX at elaboration
// time via $readmemh instead of being hardcoded in RTL, so firmware can be
// changed by regenerating the .hex file rather than editing/re-synthesizing
// this module. boot_rom.hex currently contains the same 3-instruction test
// program (SPI control-register write) followed by NOP fill that was
// previously hardcoded here - content is unchanged, only the loading
// mechanism is.
module instr_mem #(
    parameter DEPTH    = 256,
    parameter ADDR_HI  = 9,   // top addr bit: addr[ADDR_HI:2] selects DEPTH words
    parameter BOOT_HEX = "boot_rom.hex"
)(
    input  wire [31:0] addr,
    output wire [31:0] instr
);
    reg [31:0] mem [0:DEPTH-1];

    initial begin
        $readmemh(BOOT_HEX, mem);
    end

    assign instr = mem[addr[ADDR_HI:2]];
endmodule
