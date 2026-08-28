`timescale 1ns / 1ps

module datapath (
    input wire clk,
    input wire rst,
    output wire [31:0] pc_out,
    output wire [31:0] alu_result,
    output wire [31:0] instr,
    output wire        reg_write,
    
    input wire [31:0]  instr_rdata,
    output wire [31:0] instr_addr,

    output wire [31:0] data_addr,
    output wire [31:0] data_wdata,
    output wire        data_we,
    output wire        data_re,
    output wire [1:0]  mem_size,
    output wire        mem_signed,

    input wire [31:0]  data_rdata
);

    localparam OP_R      = 7'b0110011;
    localparam OP_I_ALU  = 7'b0010011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;
    localparam OP_CUSTOM = 7'b0001011;

    localparam NOP = 32'h00000013;

    function uses_rs1;
        input [31:0] insn;
        reg [6:0] op;
        reg [2:0] f3;
        begin
            op = insn[6:0];
            f3 = insn[14:12];
            case (op)
                OP_R, OP_I_ALU, OP_LOAD, OP_STORE, OP_BRANCH, OP_JALR: uses_rs1 = 1'b1;
                OP_CUSTOM: uses_rs1 = (f3 == 3'b000);
                default: uses_rs1 = 1'b0;
            endcase
        end
    endfunction

    function uses_rs2;
        input [31:0] insn;
        reg [6:0] op;
        reg [2:0] f3;
        begin
            op = insn[6:0];
            f3 = insn[14:12];
            case (op)
                OP_R, OP_STORE, OP_BRANCH: uses_rs2 = 1'b1;
                OP_CUSTOM: uses_rs2 = (f3 == 3'b000);
                default: uses_rs2 = 1'b0;
            endcase
        end
    endfunction

    // IF stage
    wire [31:0] pc_next;
    wire [31:0] pc_plus4;

    // ID stage
    wire [6:0]  id_opcode;
    wire [4:0]  id_rd_addr;
    wire [2:0]  id_funct3;
    wire [4:0]  id_rs1;
    wire [4:0]  id_rs2;
    wire [6:0]  id_funct7;
    wire [31:0] id_rd1_raw;
    wire [31:0] id_rd2_raw;
    wire [31:0] id_rd1;
    wire [31:0] id_rd2;
    wire [31:0] id_imm;

    wire id_reg_write;
    wire id_alu_src;
    wire id_mem_write;
    wire id_mem_read;
    wire id_mem_to_reg;
    wire id_branch;
    wire id_jump;
    wire id_jalr;
    wire id_lui;
    wire id_auipc;
    wire id_mac_en;
    wire id_mac_clr;
    wire id_mem_signed;
    wire [1:0] id_alu_op;
    wire [1:0] id_mem_size;
    wire [4:0] id_alu_ctrl;

    // IF/ID Registers
    reg [31:0] if_id_pc;
    reg [31:0] if_id_pc_plus4;
    reg [31:0] if_id_instr;

    // ID/EX Registers
    reg [31:0] id_ex_pc;
    reg [31:0] id_ex_pc_plus4;
    reg [31:0] id_ex_rd1;
    reg [31:0] id_ex_rd2;
    reg [31:0] id_ex_imm;
    reg [4:0]  id_ex_rs1;
    reg [4:0]  id_ex_rs2;
    reg [4:0]  id_ex_rd;
    reg [2:0]  id_ex_funct3;
    reg        id_ex_reg_write;
    reg        id_ex_alu_src;
    reg        id_ex_mem_write;
    reg        id_ex_mem_read;
    reg        id_ex_mem_to_reg;
    reg        id_ex_branch;
    reg        id_ex_jump;
    reg        id_ex_jalr;
    reg        id_ex_lui;
    reg        id_ex_auipc;
    reg        id_ex_mac_en;
    reg        id_ex_mac_clr;
    reg        id_ex_mem_signed;
    reg [1:0]  id_ex_mem_size;
    reg [4:0]  id_ex_alu_ctrl;

    // EX stage
    wire [31:0] ex_forward_data;
    wire [31:0] wb_data;
    reg  [1:0]  forward_a;
    reg  [1:0]  forward_b;
    wire [31:0] ex_rs1_data;
    wire [31:0] ex_rs2_data;
    wire [31:0] ex_alu_a;
    wire [31:0] ex_alu_b;
    wire [31:0] acc;
    wire        zero;
    reg         branch_taken;
    wire [31:0] ex_branch_target;
    wire [31:0] ex_jalr_target;
    wire        ex_redirect;
    wire [31:0] ex_redirect_target;

    // EX/MEM Registers
    reg [31:0] ex_mem_alu_result;
    reg [31:0] ex_mem_store_data;
    reg [31:0] ex_mem_pc_plus4;
    reg [31:0] ex_mem_imm;
    reg [4:0]  ex_mem_rd;
    reg        ex_mem_reg_write;
    reg        ex_mem_mem_write;
    reg        ex_mem_mem_read;
    reg        ex_mem_mem_to_reg;
    reg        ex_mem_jump;
    reg        ex_mem_jalr;
    reg        ex_mem_lui;
    reg        ex_mem_mem_signed;
    reg [1:0]  ex_mem_mem_size;

    // MEM/WB Registers
    reg [31:0] mem_wb_alu_result;
    reg [31:0] mem_wb_mem_rd;
    reg [31:0] mem_wb_pc_plus4;
    reg [31:0] mem_wb_imm;
    reg [4:0]  mem_wb_rd;
    reg        mem_wb_reg_write;
    reg        mem_wb_mem_to_reg;
    reg        mem_wb_jump;
    reg        mem_wb_jalr;
    reg        mem_wb_lui;

    wire load_use_hazard;
    wire stall;
    wire flush;

    assign pc_plus4 = pc_out + 32'd4;
    assign pc_next  = flush ? ex_redirect_target :
                      stall ? pc_out             :
                              pc_plus4;

    pc u_pc (
        .clk(clk),
        .rst(rst),
        .pc_next(pc_next),
        .pc_out(pc_out)
    );

    assign id_opcode  = if_id_instr[6:0];
    assign id_rd_addr = if_id_instr[11:7];
    assign id_funct3  = if_id_instr[14:12];
    assign id_rs1     = if_id_instr[19:15];
    assign id_rs2     = if_id_instr[24:20];
    assign id_funct7  = if_id_instr[31:25];

    control_unit u_ctrl (
        .opcode(id_opcode),
        .funct3(id_funct3),
        .funct7(id_funct7),
        .reg_write(id_reg_write),
        .alu_src(id_alu_src),
        .alu_op(id_alu_op),
        .mem_write(id_mem_write),
        .mem_read(id_mem_read),
        .mem_to_reg(id_mem_to_reg),
        .branch(id_branch),
        .jump(id_jump),
        .jalr(id_jalr),
        .mem_size(id_mem_size),
        .mem_signed(id_mem_signed),
        .lui(id_lui),
        .auipc(id_auipc),
        .mac_en(id_mac_en),
        .mac_clr(id_mac_clr),
        .alu_ctrl(id_alu_ctrl)
    );

    imm_gen u_immgen (
        .instr(if_id_instr),
        .imm_out(id_imm)
    );

    reg_file u_rf (
        .clk(clk),
        .rst(rst),
        .we(mem_wb_reg_write),
        .rs1(id_rs1),
        .rs2(id_rs2),
        .rd(mem_wb_rd),
        .wd(wb_data),
        .rd1(id_rd1_raw),
        .rd2(id_rd2_raw)
    );

    // Hazard bypass structural configurations
    assign id_rd1 = (id_rs1 == 5'b00000) ? 32'h00000000 :
                    (mem_wb_reg_write && (mem_wb_rd == id_rs1)) ? wb_data : id_rd1_raw;

    assign id_rd2 = (id_rs2 == 5'b00000) ? 32'h00000000 :
                    (mem_wb_reg_write && (mem_wb_rd == id_rs2)) ? wb_data : id_rd2_raw;

    assign load_use_hazard = id_ex_mem_read && (id_ex_rd != 5'b00000) &&
                            ((uses_rs1(if_id_instr) && (id_ex_rd == id_rs1)) ||
                             (uses_rs2(if_id_instr) && (id_ex_rd == id_rs2)));

    assign stall = load_use_hazard;
    assign flush = ex_redirect;

    // IF/ID Pipeline Register with Corrected Synchronous Flush
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            if_id_pc       <= 32'h00000000;
            if_id_pc_plus4 <= 32'h00000000;
            if_id_instr    <= NOP;
        end else if (flush) begin
            if_id_pc       <= 32'h00000000;
            if_id_pc_plus4 <= 32'h00000000;
            if_id_instr    <= NOP; // Overwrite fetched transient instructions on control transfer
        end else if (!stall) begin
            if_id_pc       <= pc_out;
            if_id_pc_plus4 <= pc_plus4;
            if_id_instr    <= instr_rdata;
        end
    end

    // ID/EX Pipeline Register
    always @(posedge clk or posedge rst) begin
        // Async reset kept exclusive of flush/stall (Yosys synthesis
        // requirement: the reset condition of a multi-edge block must be a
        // simple signal; combined conditions trigger "Multiple edge sensitive
        // events" in proc_dff). Logically identical to if (rst||flush||stall).
        if (rst) begin
            id_ex_pc           <= 32'h00000000;
            id_ex_pc_plus4     <= 32'h00000000;
            id_ex_rd1          <= 32'h00000000;
            id_ex_rd2          <= 32'h00000000;
            id_ex_imm          <= 32'h00000000;
            id_ex_rs1          <= 5'b00000;
            id_ex_rs2          <= 5'b00000;
            id_ex_rd           <= 5'b00000;
            id_ex_funct3       <= 3'b000;
            id_ex_reg_write    <= 1'b0;
            id_ex_alu_src      <= 1'b0;
            id_ex_mem_write    <= 1'b0;
            id_ex_mem_read     <= 1'b0;
            id_ex_mem_to_reg   <= 1'b0;
            id_ex_branch       <= 1'b0;
            id_ex_jump         <= 1'b0;
            id_ex_jalr         <= 1'b0;
            id_ex_lui          <= 1'b0;
            id_ex_auipc        <= 1'b0;
            id_ex_mac_en       <= 1'b0;
            id_ex_mac_clr      <= 1'b0;
            id_ex_mem_signed   <= 1'b0;
            id_ex_mem_size     <= 2'b10;
            id_ex_alu_ctrl     <= 5'b00000;
        end else if (flush || stall) begin
            id_ex_pc           <= 32'h00000000;
            id_ex_pc_plus4     <= 32'h00000000;
            id_ex_rd1          <= 32'h00000000;
            id_ex_rd2          <= 32'h00000000;
            id_ex_imm          <= 32'h00000000;
            id_ex_rs1          <= 5'b00000;
            id_ex_rs2          <= 5'b00000;
            id_ex_rd           <= 5'b00000;
            id_ex_funct3       <= 3'b000;
            id_ex_reg_write    <= 1'b0;
            id_ex_alu_src      <= 1'b0;
            id_ex_mem_write    <= 1'b0;
            id_ex_mem_read     <= 1'b0;
            id_ex_mem_to_reg   <= 1'b0;
            id_ex_branch       <= 1'b0;
            id_ex_jump         <= 1'b0;
            id_ex_jalr         <= 1'b0;
            id_ex_lui          <= 1'b0;
            id_ex_auipc        <= 1'b0;
            id_ex_mac_en       <= 1'b0;
            id_ex_mac_clr      <= 1'b0;
            id_ex_mem_signed   <= 1'b0;
            id_ex_mem_size     <= 2'b10;
            id_ex_alu_ctrl     <= 5'b00000;
        end else begin
            id_ex_pc           <= if_id_pc;
            id_ex_pc_plus4     <= if_id_pc_plus4;
            id_ex_rd1          <= id_rd1;
            id_ex_rd2          <= id_rd2;
            id_ex_imm          <= id_imm;
            id_ex_rs1          <= id_rs1;
            id_ex_rs2          <= id_rs2;
            id_ex_rd           <= id_rd_addr;
            id_ex_funct3       <= id_funct3;
            id_ex_reg_write    <= id_reg_write;
            id_ex_alu_src      <= id_alu_src;
            id_ex_mem_write    <= id_mem_write;
            id_ex_mem_read     <= id_mem_read;
            id_ex_mem_to_reg   <= id_mem_to_reg;
            id_ex_branch       <= id_branch;
            id_ex_jump         <= id_jump;
            id_ex_jalr         <= id_jalr;
            id_ex_lui          <= id_lui;
            id_ex_auipc        <= id_auipc;
            id_ex_mac_en       <= id_mac_en;
            id_ex_mac_clr      <= id_mac_clr;
            id_ex_mem_signed   <= id_mem_signed;
            id_ex_mem_size     <= id_mem_size;
            id_ex_alu_ctrl     <= id_alu_ctrl;
        end
    end

    assign ex_forward_data = (ex_mem_jump | ex_mem_jalr) ? ex_mem_pc_plus4 :
                             ex_mem_lui                 ? ex_mem_imm        :
                                                          ex_mem_alu_result;

    always @(*) begin
        forward_a = 2'b00;
        if (ex_mem_reg_write && !ex_mem_mem_to_reg && (ex_mem_rd != 5'b00000) && (ex_mem_rd == id_ex_rs1)) begin
            forward_a = 2'b10;
        end else if (mem_wb_reg_write && (mem_wb_rd != 5'b00000) && (mem_wb_rd == id_ex_rs1)) begin
            forward_a = 2'b01;
        end
    end

    always @(*) begin
        forward_b = 2'b00;
        if (ex_mem_reg_write && !ex_mem_mem_to_reg && (ex_mem_rd != 5'b00000) && (ex_mem_rd == id_ex_rs2)) begin
            forward_b = 2'b10;
        end else if (mem_wb_reg_write && (mem_wb_rd != 5'b00000) && (mem_wb_rd == id_ex_rs2)) begin
            forward_b = 2'b01;
        end
    end

    assign ex_rs1_data = (forward_a == 2'b10) ? ex_forward_data : (forward_a == 2'b01) ? wb_data : id_ex_rd1;
    assign ex_rs2_data = (forward_b == 2'b10) ? ex_forward_data : (forward_b == 2'b01) ? wb_data : id_ex_rd2;
    assign ex_alu_a    = id_ex_auipc ? id_ex_pc : ex_rs1_data;
    assign ex_alu_b    = (id_ex_alu_src || id_ex_auipc) ? id_ex_imm : ex_rs2_data;

    alu u_alu (
        .a(ex_alu_a),
        .b(ex_alu_b),
        .acc(acc),
        .alu_ctrl(id_ex_alu_ctrl),
        .result(alu_result),
        .zero(zero)
    );

    always @(*) begin
        branch_taken = 1'b0;
        if (id_ex_branch) begin
            case (id_ex_funct3)
                3'b000:  branch_taken = zero;
                3'b001:  branch_taken = ~zero;
                3'b100:  branch_taken = alu_result[0];
                3'b101:  branch_taken = ~alu_result[0];
                3'b110:  branch_taken = alu_result[0];
                3'b111:  branch_taken = ~alu_result[0];
                default: branch_taken = 1'b0;
            endcase
        end
    end

    assign ex_branch_target   = id_ex_pc + id_ex_imm;
    assign ex_jalr_target     = (ex_rs1_data + id_ex_imm) & 32'hFFFFFFFE;
    assign ex_redirect        = id_ex_jump | id_ex_jalr | branch_taken;
    assign ex_redirect_target = id_ex_jalr ? ex_jalr_target : ex_branch_target;

    mac_unit u_mac (
        .clk(clk),
        .rst(rst),
        .mac_en(id_ex_mac_en),
        .mac_clr(id_ex_mac_clr),
        .mac_in(alu_result),
        .acc(acc)
    );

    // EX/MEM Pipeline Register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ex_mem_alu_result <= 32'h00000000;
            ex_mem_store_data <= 32'h00000000;
            ex_mem_pc_plus4   <= 32'h00000000;
            ex_mem_imm        <= 32'h00000000;
            ex_mem_rd         <= 5'b00000;
            ex_mem_reg_write  <= 1'b0;
            ex_mem_mem_write  <= 1'b0;
            ex_mem_mem_read   <= 1'b0;
            ex_mem_mem_to_reg <= 1'b0;
            ex_mem_jump       <= 1'b0;
            ex_mem_jalr       <= 1'b0;
            ex_mem_lui        <= 1'b0;
            ex_mem_mem_signed <= 1'b0;
            ex_mem_mem_size   <= 2'b10;
        end else begin
            ex_mem_alu_result <= alu_result;
            ex_mem_store_data <= ex_rs2_data;
            ex_mem_pc_plus4   <= id_ex_pc_plus4;
            ex_mem_imm        <= id_ex_imm;
            ex_mem_rd         <= id_ex_rd;
            ex_mem_reg_write  <= id_ex_reg_write;
            ex_mem_mem_write  <= id_ex_mem_write;
            ex_mem_mem_read   <= id_ex_mem_read;
            ex_mem_mem_to_reg <= id_ex_mem_to_reg;
            ex_mem_jump       <= id_ex_jump;
            ex_mem_jalr       <= id_ex_jalr;
            ex_mem_lui        <= id_ex_lui;
            ex_mem_mem_signed <= id_ex_mem_signed;
            ex_mem_mem_size   <= id_ex_mem_size;
        end
    end

    // MEM/WB Pipeline Register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_wb_alu_result <= 32'h00000000;
            mem_wb_mem_rd     <= 32'h00000000;
            mem_wb_pc_plus4   <= 32'h00000000;
            mem_wb_imm        <= 32'h00000000;
            mem_wb_rd         <= 5'b00000;
            mem_wb_reg_write  <= 1'b0;
            mem_wb_mem_to_reg <= 1'b0;
            mem_wb_jump       <= 1'b0;
            mem_wb_jalr       <= 1'b0;
            mem_wb_lui        <= 1'b0;
        end else begin
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_mem_rd     <= data_rdata;
            mem_wb_pc_plus4   <= ex_mem_pc_plus4;
            mem_wb_imm        <= ex_mem_imm;
            mem_wb_rd         <= ex_mem_rd;
            mem_wb_reg_write  <= ex_mem_reg_write;
            mem_wb_mem_to_reg <= ex_mem_mem_to_reg;
            mem_wb_jump       <= ex_mem_jump;
            mem_wb_jalr       <= ex_mem_jalr;
            mem_wb_lui        <= ex_mem_lui;
        end
    end

    assign wb_data = (mem_wb_jump | mem_wb_jalr) ? mem_wb_pc_plus4 :
                     mem_wb_mem_to_reg           ? mem_wb_mem_rd    :
                     mem_wb_lui                  ? mem_wb_imm       :
                                                   mem_wb_alu_result;

    assign instr_addr = pc_out;
    assign instr      = instr_rdata;
    assign data_addr  = ex_mem_alu_result;
    assign data_wdata = ex_mem_store_data;
    assign data_we    = ex_mem_mem_write;
    assign data_re    = ex_mem_mem_read;
    assign mem_size   = ex_mem_mem_size;
    assign mem_signed = ex_mem_mem_signed;
    assign reg_write  = mem_wb_reg_write;

endmodule