// ==============================================================================
// FILE: reg_file.v
// DESCRIPTION: 32-entry RV32IM general-purpose register file (x0-x31).
//              x0 is hard-wired to zero. Synchronous write on posedge clk,
//              synchronous active-high reset clears all entries (required
//              for DFT/scan and deterministic post-reset simulation/
//              synthesis behavior - a register file with no reset is not
//              GDSII/OpenLane clean and was flagged as such).
//              Write-during-read same-cycle write-data forwarding is
//              intentionally left to the caller (see Data_Path.v's
//              id_rd1/id_rd2 bypass muxes) rather than duplicated here.
// ==============================================================================
`timescale 1ns / 1ps

module reg_file (
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] wd,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);
    reg [31:0] regs [0:31];

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'h00000000;
        end else if (we && rd != 5'b00000) begin
            regs[rd] <= wd;
        end
    end

    assign rd1 = (rs1 == 5'b00000) ? 32'h00000000 : regs[rs1];
    assign rd2 = (rs2 == 5'b00000) ? 32'h00000000 : regs[rs2];

endmodule
