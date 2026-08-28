module top (
    input  wire        clk,
    input  wire        rst,

    output wire [31:0] pc_out,
    output wire [31:0] alu_result,
    output wire [31:0] instr,
    output wire        reg_write
);

wire [31:0] instr_addr;
wire [31:0] instr_rdata;

wire [31:0] data_addr;
wire [31:0] data_wdata;
wire [31:0] data_rdata;
wire        data_we;
wire        data_re;
wire [1:0]  mem_size;
wire        mem_signed;

// CPU
datapath u_datapath (
    .clk(clk),
    .rst(rst),

    .pc_out(pc_out),
    .alu_result(alu_result),
    .instr(instr),
    .reg_write(reg_write),

    .instr_addr(instr_addr),
    .instr_rdata(instr_rdata),

    .data_addr(data_addr),
    .data_wdata(data_wdata),
    .data_we(data_we),
    .data_re(data_re),
    .mem_size(mem_size),
    .mem_signed(mem_signed),
    .data_rdata(data_rdata)
);

// Instruction Memory
instr_mem u_imem (
    .addr(instr_addr),
    .instr(instr_rdata)
);

// Data Memory
data_mem u_dmem (
    .clk(clk),
    .we(data_we),
    .re(data_re),

    .mem_size(mem_size),
    .mem_signed(mem_signed),

    .addr(data_addr),
    .wd(data_wdata),
    .rd(data_rdata)
);
endmodule
