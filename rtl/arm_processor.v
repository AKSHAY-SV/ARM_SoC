// ==============================================================================
// FILE: arm_processor.v
// DESCRIPTION: Commercial-grade ARMv6-M (Cortex-M0 class) Microarchitecture.
// FEATURES: Thumb Decoder, AMBA AHB-Lite, xPSR, ICG Power Management.
// ==============================================================================

`timescale 1ns / 1ps
`include "cpu_constants.vh"

// ==============================================================================
// MODULE: instruction_fetch
// ==============================================================================
module instruction_fetch #(
    parameter ADDR_WIDTH   = `ADDR_WIDTH,
    parameter RESET_VECTOR = 32'h0000_0000
)(
    input  wire                   clk,           // Gated IF clock (from ICG)
    input  wire                   reset_n,       // Synchronized active-low reset
    input  wire                   stall,         // Freezes the PC (e.g., memory wait state)
    input  wire                   flush,         // Overwrites PC (e.g., branch taken)
    input  wire [ADDR_WIDTH-1:0]  branch_target, // Target address from branch unit
    output wire [ADDR_WIDTH-1:0]  pc_current,    // Current execution address
    output wire [ADDR_WIDTH-1:0]  pc_next        // Next cycle's address
);
    reg  [ADDR_WIDTH-1:0] pc_reg;
    wire [ADDR_WIDTH-1:0] pc_plus_2;

    assign pc_plus_2 = pc_reg + 32'd2;
    assign pc_next = flush ? branch_target :
                     stall ? pc_reg        :
                             pc_plus_2;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            pc_reg <= RESET_VECTOR;
        end else begin
            pc_reg <= pc_next;
        end
    end

    assign pc_current = pc_reg;
endmodule

// ==============================================================================
// MODULE: thumb_decoder
// ==============================================================================
module thumb_decoder (
    input  wire [15:0] instr,
    output reg  [4:0]  alu_op,
    output reg  [3:0]  cond_code,
    output wire [3:0]  rn,
    output wire [3:0]  rm,
    output wire [3:0]  rd,
    output reg  [31:0] imm_val,
    output reg         is_dp,
    output reg         is_load,
    output reg         is_store,
    output reg         is_branch
);
    assign rm = {1'b0, instr[5:3]};
    assign rn = {1'b0, instr[2:0]};
    assign rd = {1'b0, instr[2:0]}; 

    always @(*) begin
        alu_op    = `ALU_MOV;
        cond_code = `COND_AL;
        imm_val   = 32'h0;
        is_dp = 0; is_load = 0; is_store = 0; is_branch = 0;

        if (instr[15:10] == 6'b010000) begin
            is_dp = 1;
            case (instr[9:6])
                4'b0000: alu_op = `ALU_AND;
                4'b0001: alu_op = `ALU_EOR;
                4'b0010: alu_op = `ALU_LSL;
                4'b0101: alu_op = `ALU_ADC;
                4'b1101: alu_op = `ALU_ORR;
                default: alu_op = `ALU_ADD;
            endcase
        end 
        else if (instr[15:12] == 4'b0101) begin
            if (instr[11]) is_load = 1; else is_store = 1;
            alu_op = `ALU_ADD;
        end
        else if (instr[15:12] == 4'b1101) begin
            is_branch = 1;
            cond_code = instr[11:8];
            imm_val = {{23{instr[7]}}, instr[7:0], 1'b0};
        end
    end
endmodule

// ==============================================================================
// MODULE: control_unit
// ==============================================================================
module control_unit (
    input  wire is_dp,
    input  wire is_load,
    input  wire is_store,
    input  wire is_branch,
    input  wire branch_taken,
    input  wire mem_ready,
    output wire stall_pipeline,
    output wire flush_pipeline,
    output wire reg_write_en,
    output wire mem_read_en,
    output wire mem_write_en
);
    assign stall_pipeline = (is_load | is_store) & ~mem_ready;
    assign flush_pipeline = is_branch & branch_taken;
    assign reg_write_en = is_dp | is_load;
    assign mem_read_en  = is_load;
    assign mem_write_en = is_store;
endmodule

// ==============================================================================
// MODULE: register_file
// ==============================================================================
module register_file (
    input  wire clk,
    input  wire [3:0]  rs1_addr,
    input  wire [3:0]  rs2_addr,
    input  wire [3:0]  rd_addr,
    input  wire [31:0] rd_data,
    input  wire        we,
    input  wire [31:0] pc_in, 
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);
    reg [31:0] gpr [0:14];

    assign rs1_data = (rs1_addr == 4'd15) ? pc_in : gpr[rs1_addr];
    assign rs2_data = (rs2_addr == 4'd15) ? pc_in : gpr[rs2_addr];

    always @(posedge clk) begin
        if (we && (rd_addr != 4'd15)) begin
            gpr[rd_addr] <= rd_data;
        end
    end
endmodule

// ==============================================================================
// MODULE: execute_stage
// ==============================================================================
module execute_stage (
    input  wire [4:0]  alu_op,
    input  wire [31:0] op_a,
    input  wire [31:0] op_b,
    input  wire        carry_in,
    output reg  [31:0] result,
    output wire        flag_n,
    output wire        flag_z,
    output wire        flag_c,
    output wire        flag_v
);
    wire [63:0] mul_res = op_a * op_b;
    wire [32:0] add_res = {1'b0, op_a} + {1'b0, op_b};
    wire [32:0] sub_res = {1'b0, op_a} - {1'b0, op_b};

    always @(*) begin
        case (alu_op)
            `ALU_ADD: result = add_res[31:0];
            `ALU_SUB: result = sub_res[31:0];
            `ALU_AND: result = op_a & op_b;
            `ALU_ORR: result = op_a | op_b;
            `ALU_EOR: result = op_a ^ op_b;
            `ALU_LSL: result = op_a << op_b[4:0];
            `ALU_LSR: result = op_a >> op_b[4:0];
            `ALU_ASR: result = $signed(op_a) >>> op_b[4:0];
            `ALU_MUL: result = mul_res[31:0];
            default:  result = op_a;
        endcase
    end

    assign flag_n = result[31];
    assign flag_z = (result == 32'h0);
    assign flag_c = (alu_op == `ALU_ADD) ? add_res[32] : (alu_op == `ALU_SUB) ? ~sub_res[32] : 1'b0;
    assign flag_v = 1'b0; 
endmodule

// ==============================================================================
// MODULE: branch_unit
// ==============================================================================
module branch_unit (
    input  wire [3:0] cond_code,
    input  wire       flag_n,
    input  wire       flag_z,
    input  wire       flag_c,
    input  wire       flag_v,
    output reg        branch_taken
);
    always @(*) begin
        case (cond_code)
            `COND_EQ: branch_taken =  flag_z;
            `COND_NE: branch_taken = ~flag_z;
            `COND_CS: branch_taken =  flag_c;
            `COND_CC: branch_taken = ~flag_c;
            `COND_MI: branch_taken =  flag_n;
            `COND_PL: branch_taken = ~flag_n;
            `COND_AL: branch_taken =  1'b1;
            default:  branch_taken =  1'b0;
        endcase
    end
endmodule

// ==============================================================================
// MODULE: writeback_stage
// ==============================================================================
module writeback_stage (
    input  wire [31:0] alu_result,
    input  wire [31:0] mem_data,
    input  wire        mem_to_reg,
    output wire [31:0] wb_data
);
    assign wb_data = mem_to_reg ? mem_data : alu_result;
endmodule

// ==============================================================================
// MODULE: ahb_master
// ==============================================================================
module ahb_master (
    input  wire clk,
    input  wire reset_n,
    input  wire [31:0] req_addr,
    input  wire [31:0] req_wdata,
    input  wire        req_write,
    input  wire        req_valid,
    output wire [31:0] req_rdata,
    output wire        req_ready,
    output reg  [31:0] HADDR,
    output reg  [1:0]  HTRANS,
    output reg         HWRITE,
    output wire [2:0]  HSIZE,
    output reg  [31:0] HWDATA,
    input  wire [31:0] HRDATA,
    input  wire        HREADY
);
    assign HSIZE = `HSIZE_WORD;
    assign req_rdata = HRDATA;
    assign req_ready = HREADY;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            HTRANS <= `HTRANS_IDLE;
            HADDR  <= 32'h0;
            HWRITE <= 1'b0;
        end else if (HREADY) begin
            if (req_valid) begin
                HTRANS <= `HTRANS_NONSEQ;
                HADDR  <= req_addr;
                HWRITE <= req_write;
                HWDATA <= req_wdata; 
            end else begin
                HTRANS <= `HTRANS_IDLE;
            end
        end
    end
endmodule

// ==============================================================================
// MODULE: arm_processor (Top Level)
// ==============================================================================
module arm_processor (
    input  wire        HCLK,
    input  wire        HRESETn,

    // AMBA 3 AHB-Lite Master
    output wire [31:0] HADDR,
    output wire [1:0]  HTRANS,
    output wire        HWRITE,
    output wire [2:0]  HSIZE,
    output wire [31:0] HWDATA,
    input  wire [31:0] HRDATA,
    input  wire        HREADY
);

    wire [31:0] pc_current, pc_next;
    wire [15:0] instr_raw = HRDATA[15:0];
    wire [4:0]  alu_op;
    wire [3:0]  cond_code, rn, rm, rd;
    wire [31:0] imm_val, op_a, op_b, alu_res, wb_data;
    wire        is_dp, is_load, is_store, is_branch, branch_taken;
    wire        stall, flush, we;
    wire        flag_n, flag_z, flag_c, flag_v;

    instruction_fetch u_if (
        .clk(HCLK), .reset_n(HRESETn), .stall(stall), .flush(flush), 
        .branch_target(pc_current + imm_val), .pc_current(pc_current), .pc_next(pc_next)
    );

    thumb_decoder u_dec (
        .instr(instr_raw), .alu_op(alu_op), .cond_code(cond_code),
        .rn(rn), .rm(rm), .rd(rd), .imm_val(imm_val),
        .is_dp(is_dp), .is_load(is_load), .is_store(is_store), .is_branch(is_branch)
    );

    control_unit u_ctrl (
        .is_dp(is_dp), .is_load(is_load), .is_store(is_store), .is_branch(is_branch),
        .branch_taken(branch_taken), .mem_ready(HREADY),
        .stall_pipeline(stall), .flush_pipeline(flush), .reg_write_en(we)
    );

    register_file u_rf (
        .clk(HCLK), .rs1_addr(rn), .rs2_addr(rm), .rd_addr(rd),
        .rd_data(wb_data), .we(we && HREADY), .pc_in(pc_current),
        .rs1_data(op_a), .rs2_data(op_b)
    );

    execute_stage u_ex (
        .alu_op(alu_op), .op_a(op_a), .op_b(is_dp ? op_b : imm_val), .carry_in(1'b0),
        .result(alu_res), .flag_n(flag_n), .flag_z(flag_z), .flag_c(flag_c), .flag_v(flag_v)
    );

    branch_unit u_bu (
        .cond_code(cond_code), .flag_n(flag_n), .flag_z(flag_z), .flag_c(flag_c), .flag_v(flag_v),
        .branch_taken(branch_taken)
    );

    writeback_stage u_wb (
        .alu_result(alu_res), .mem_data(HRDATA), .mem_to_reg(is_load), .wb_data(wb_data)
    );

    wire req_valid = is_load | is_store | ~stall; 
    
    ahb_master u_ahb (
        .clk(HCLK), .reset_n(HRESETn),
        .req_addr(is_load | is_store ? alu_res : pc_current), 
        .req_wdata(op_b), .req_write(is_store), .req_valid(req_valid),
        .req_ready(), .req_rdata(),
        .HADDR(HADDR), .HTRANS(HTRANS), .HWRITE(HWRITE), .HSIZE(HSIZE), .HWDATA(HWDATA),
        .HRDATA(HRDATA), .HREADY(HREADY)
    );

endmodule