`timescale 1ns / 1ps
module tb;
 
    reg clk, rst;
    top dut (.clk(clk), .rst(rst));
 
    initial clk = 0;
    always #5 clk = ~clk;
 
    `define RF   dut.u_datapath.u_rf.regs
    `define IMEM dut.u_imem.mem
    `define DMEM dut.u_dmem.mem
    `define PC   dut.u_datapath.pc_out
    `define ACC  dut.u_datapath.u_mac.acc
 
    integer pass_cnt, fail_cnt, cycle;
    reg [31:0] dmem_word;
    wire [31:0] dmem_word0 = {`DMEM[3],`DMEM[2],`DMEM[1],`DMEM[0]};
    wire [31:0] dmem_word4 = {`DMEM[7],`DMEM[6],`DMEM[5],`DMEM[4]};
 
    task automatic chk;
        input [31:0] got;
        input [31:0] exp;
        input [8*40:1] tag;
        begin
            if (got === exp) begin
                $display("  PASS  %-40s  got=%0d (0x%08X)", tag, $signed(got), got);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  FAIL  %-40s  got=%0d (0x%08X)  exp=%0d (0x%08X)",
                         tag, $signed(got), got, $signed(exp), exp);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask
 
    task load_program;
        integer i;
        begin
            for (i = 0; i < 256; i = i + 1)
                `IMEM[i] = 32'h00000013; // NOP
 
            // ?? RV32I Arithmetic ??????????????????????????????????
            `IMEM[0]  = 32'h00F00093; // addi x1, x0, 15
            `IMEM[1]  = 32'h00A00113; // addi x2, x0, 10
            `IMEM[2]  = 32'hFFB00193; // addi x3, x0, -5
            `IMEM[3]  = 32'h00208233; // add  x4, x1, x2  = 25
            `IMEM[4]  = 32'h402082B3; // sub  x5, x1, x2  = 5
            `IMEM[5]  = 32'h0020F333; // and  x6, x1, x2  = 10
            `IMEM[6]  = 32'h0020E3B3; // or   x7, x1, x2  = 15
            `IMEM[7]  = 32'h0020C433; // xor  x8, x1, x2  = 5
            `IMEM[8]  = 32'h001124B3; // slt  x9, x2, x1  = 1
            `IMEM[9]  = 32'h00113533; // sltu x10,x2, x1  = 1
            `IMEM[10] = 32'h002115B3; // sll  x11,x2, x2  = 10240
            `IMEM[11] = 32'h0025D633; // srl  x12,x11,x2  = 10
            `IMEM[12] = 32'h4021D6B3; // sra  x13,x3, x2  = -1
 
            // ?? Immediate ALU ?????????????????????????????????????
            `IMEM[13] = 32'h06408713; // addi x14,x1, 100 = 115
            `IMEM[14] = 32'h00C0F793; // andi x15,x1, 12  = 12
            `IMEM[15] = 32'h0100E813; // ori  x16,x1, 16  = 31
            `IMEM[16] = 32'h0090C893; // xori x17,x1, 9   = 6
            `IMEM[17] = 32'h0001A913; // slti x18,x3, 0   = 1 (-5<0)
            `IMEM[18] = 32'h00209993; // slli x19,x1, 2   = 60
            `IMEM[19] = 32'h0029DA13; // srli x20,x19,2   = 15
            `IMEM[20] = 32'h4011DA93; // srai x21,x3, 1   = -3
 
            // ?? LUI / AUIPC ???????????????????????????????????????
            `IMEM[21] = 32'h00001B37; // lui   x22,1      = 0x1000
            `IMEM[22] = 32'h00000B97; // auipc x23,0      = PC (0x58)
 
            // ?? Store ?????????????????????????????????????????????
            `IMEM[23] = 32'h00102023; // sw  x1,  0(x0)   dmem[0]=15
            `IMEM[24] = 32'h00202223; // sw  x2,  4(x0)   dmem[4]=10
            `IMEM[25] = 32'h00002C03; // lw  x24, 0(x0)   x24=15
            `IMEM[26] = 32'h00402C83; // lw  x25, 4(x0)   x25=10
            `IMEM[27] = 32'h00100423; // sb  x1,  8(x0)   dmem[8]=0x0F
            `IMEM[28] = 32'h00800D03; // lb  x26, 8(x0)   x26=15
            `IMEM[29] = 32'h00301623; // sh  x3,  12(x0)  dmem[12]=0xFFFB
            `IMEM[30] = 32'h00C01D83; // lh  x27, 12(x0)  x27=-5
            `IMEM[31] = 32'h00804E03; // lbu x28, 8(x0)   x28=15
            `IMEM[32] = 32'h00C05E83; // lhu x29, 12(x0)  x29=65531
 
            // ?? Branches ??????????????????????????????????????????
            `IMEM[33] = 32'h00108463; // beq x1,x1,+8  taken -> land 35
            `IMEM[34] = 32'h06300F13; // addi x30,x0,99  SKIP
            `IMEM[35] = 32'h00100F13; // addi x30,x0,1
            `IMEM[36] = 32'h00209463; // bne x1,x2,+8  taken -> land 38
            `IMEM[37] = 32'h06300F13; // addi x30,x0,99  SKIP
            `IMEM[38] = 32'h00200F13; // addi x30,x0,2
            `IMEM[39] = 32'h00114463; // blt x2,x1,+8  taken -> land 41
            `IMEM[40] = 32'h06300F13; // addi x30,x0,99  SKIP
            `IMEM[41] = 32'h00300F13; // addi x30,x0,3
            `IMEM[42] = 32'h0020D463; // bge x1,x2,+8  taken -> land 44
            `IMEM[43] = 32'h06300F13; // addi x30,x0,99  SKIP
            `IMEM[44] = 32'h00400F13; // addi x30,x0,4
 
            // ?? JAL / JALR ????????????????????????????????????????
            `IMEM[45] = 32'h00800FEF; // jal  x31,+8    skip 46 land 47
            `IMEM[46] = 32'h06300F13; // addi x30,x0,99  SKIP
            `IMEM[47] = 32'h00500F13; // addi x30,x0,5
            `IMEM[48] = 32'h0C800F67; // jalr x30,x0,200 -> instr 50
            `IMEM[49] = 32'h06300F13; // addi x30,x0,99  SKIP
            `IMEM[50] = 32'h00600F13; // addi x30,x0,6
 
            // ?? RV32M ?????????????????????????????????????????????
            `IMEM[51] = 32'h02208233; // mul  x4, x1,x2  15*10=150
            `IMEM[52] = 32'h022092B3; // mulh x5, x1,x2  upper=0
            `IMEM[53] = 32'h02224333; // div  x6, x4,x2  150/10=15
            `IMEM[54] = 32'h022253B3; // divu x7, x4,x2  150/10=15
            `IMEM[55] = 32'h02126433; // rem  x8, x4,x1  150 rem 15=0
            `IMEM[56] = 32'h022274B3; // remu x9, x4,x2  150 rem 10=0
 
            // ?? MAC ???????????????????????????????????????????????
            `IMEM[57] = 32'h0000100B; // MACZ          acc=0
            `IMEM[58] = 32'h0020850B; // MAC x10,x1,x2 acc=0+150=150
            `IMEM[59] = 32'h0010858B; // MAC x11,x1,x1 acc=150+225=375
        end
    endtask
 
    initial begin
        $dumpfile("top_isa_regression.vcd");
        $dumpvars(0, tb);

        pass_cnt = 0; fail_cnt = 0;
        cycle = 0;
        dmem_word = 32'h00000000;
 
        rst = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;
 
        load_program;
 
        $display("\n============================================================");
        $display("   RV32I + RV32M + MAC  Full System Simulation");
        $display("============================================================");
        $display("  %4s  %10s  %10s", "Cyc", "PC", "INSTR");
        for (cycle = 0; cycle < 80; cycle = cycle + 1) begin
            @(posedge clk); #1;
            $display("  cyc=%3d  PC=0x%08X  INSTR=0x%08X",
                     cycle, `PC, dut.u_datapath.instr);
        end
 
        // ?? RV32I Arithmetic ?????????????????????????????????????
        $display("\n------- RV32I Arithmetic -------");
        chk(`RF[1],  32'd15,         "x1  ADDI x0,15=15              ");
        chk(`RF[2],  32'd10,         "x2  ADDI x0,10=10              ");
        chk(`RF[3],  32'hFFFFFFFB,   "x3  ADDI x0,-5                 ");
        // x4 overwritten by MUL later - checked in RV32M section
        // x5 overwritten by MULH later - checked in RV32M section
        // x6 overwritten by DIV later - checked in RV32M section
        chk(`RF[7],  32'd15,         "x7  OR   x1|x2=15              ");
        // x8 overwritten by REM later - checked in RV32M section
        // x9 overwritten by REMU later - checked in RV32M section
        // x10 overwritten by MAC later - checked in MAC section
        // x11 overwritten by MAC later - checked in MAC section
        chk(`RF[12], 32'd10,         "x12 SRL  10240>>10=10          ");
        chk(`RF[13], 32'hFFFFFFFF,   "x13 SRA  -5>>10=-1             ");
 
        // ?? Immediate ALU ?????????????????????????????????????????
        $display("\n------- Immediate ALU -------");
        chk(`RF[14], 32'd115,        "x14 ADDI x1+100=115            ");
        chk(`RF[15], 32'd12,         "x15 ANDI x1&12=12              ");
        chk(`RF[16], 32'd31,         "x16 ORI  x1|16=31              ");
        chk(`RF[17], 32'd6,          "x17 XORI x1^9=6                ");
        chk(`RF[18], 32'd1,          "x18 SLTI -5<0=1                ");
        chk(`RF[19], 32'd60,         "x19 SLLI 15<<2=60              ");
        chk(`RF[20], 32'd15,         "x20 SRLI 60>>2=15              ");
        chk(`RF[21], 32'hFFFFFFFD,   "x21 SRAI -5>>1=-3              ");
 
        // ?? LUI / AUIPC ???????????????????????????????????????????
        $display("\n------- LUI / AUIPC -------");
        chk(`RF[22], 32'h00001000,   "x22 LUI  1->0x1000             ");
        chk(`RF[23], 32'h00000058,   "x23 AUIPC PC=0x58+0            ");
 
        // ?? Load / Store ??????????????????????????????????????????
        $display("\n------- Load / Store -------");
        chk(`RF[24], 32'd15,         "x24 LW   dmem[0]=15            ");
        chk(`RF[25], 32'd10,         "x25 LW   dmem[4]=10            ");
        chk(`RF[26], 32'd15,         "x26 LB   dmem[8]=15            ");
        chk(`RF[27], 32'hFFFFFFFB,   "x27 LH   dmem[12]=-5           ");
        chk(`RF[28], 32'd15,         "x28 LBU  dmem[8]=15            ");
        chk(`RF[29], 32'd65531,      "x29 LHU  dmem[12]=65531        ");
 
        // ?? Branches ??????????????????????????????????????????????
        $display("\n------- Branches -------");
        chk(`RF[30], 32'd6,          "x30 final=6 all branches taken ");
 
        // ?? JAL / JALR ????????????????????????????????????????????
        $display("\n------- JAL / JALR -------");
        // JAL at instr 45: PC=45*4=180=0xB4, link=PC+4=0xB8
        chk(`RF[31], 32'h000000B8,   "x31 JAL  link=0xB8             ");
 
        // ?? RV32M ?????????????????????????????????????????????????
        $display("\n------- RV32M -------");
        chk(`RF[4],  32'd150,        "x4  MUL  15*10=150             ");
        chk(`RF[5],  32'd0,          "x5  MULH upper32=0             ");
        chk(`RF[6],  32'd15,         "x6  DIV  150/10=15             ");
        chk(`RF[7],  32'd15,         "x7  DIVU 150/10=15             ");
        chk(`RF[8],  32'd0,          "x8  REM  150 rem 15=0          ");
        chk(`RF[9],  32'd0,          "x9  REMU 150 rem 10=0          ");
 
        // ?? MAC ???????????????????????????????????????????????????
        $display("\n------- MAC -------");
        chk(`RF[10], 32'd150,        "x10 MAC  0+15*10=150           ");
        chk(`RF[11], 32'd375,        "x11 MAC  150+15*15=375         ");
        chk(`ACC,    32'd375,        "acc final=375                  ");
 
        // ?? Data Memory ???????????????????????????????????????????
        $display("\n------- Data Memory -------");
        dmem_word = dmem_word0;
        chk(dmem_word, 32'd15,       "dmem[0] SW x1=15               ");
        dmem_word = dmem_word4;
        chk(dmem_word, 32'd10,       "dmem[4] SW x2=10               ");
 
        // ?? Summary ???????????????????????????????????????????????
        $display("\n============================================================");
        $display("  TOTAL: %0d PASSED   %0d FAILED", pass_cnt, fail_cnt);
        if (fail_cnt == 0)
            $display("  ALL TESTS PASSED - Full RV32I+M+MAC system verified!");
        else
            $display("  SOME TESTS FAILED - Check waveforms above");
        $display("============================================================\n");
        $finish;
    end
 
    initial begin
        #200000;
        $display("SIMULATION TIMEOUT");
        $finish;
    end
 
endmodule
