`timescale 1ns/1ps

module tb_top;

reg clk;
reg rst;

wire [31:0] pc_out;
wire [31:0] alu_result;
wire [31:0] instr;
wire reg_write;

top DUT (
    .clk(clk),
    .rst(rst),
    .pc_out(pc_out),
    .alu_result(alu_result),
    .instr(instr),
    .reg_write(reg_write)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// Reset
initial begin
    rst = 1;
    #20;
    rst = 0;
end

// Waveform dump
initial begin
    $dumpfile("top.vcd");
    $dumpvars(0, tb_top);
end

// Monitor important signals
initial begin
    $display("Time\tPC\t\tInstr\t\tALU\t\tRegWrite");

    $monitor(
"t=%0t PC=%h IADDR=%h IRDATA=%h INSTR=%h",
$time,
pc_out,
DUT.instr_addr,
DUT.instr_rdata,
instr
);
end

// Finish simulation
initial begin
    #5000;

    $display("\n================================");
    $display("Simulation Finished");
    $display("PC    = %08h", pc_out);
    $display("INST  = %08h", instr);
    $display("ALU   = %08h", alu_result);
    $display("================================");

    $finish;
end

endmodule
