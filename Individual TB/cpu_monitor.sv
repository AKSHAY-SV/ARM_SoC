`timescale 1ns / 1ps

module cpu_monitor #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
)(
    input  logic                    clk,
    input  logic                    rst_n,
    // CPU Pipeline Signals (hierarchical references would be used in practice)
    input  logic [ADDR_WIDTH-1:0]   pc_out,
    input  logic [DATA_WIDTH-1:0]   alu_result,
    input  logic [DATA_WIDTH-1:0]   instr,
    input  logic                    reg_write,
    input  logic [DATA_WIDTH-1:0]   instr_addr,
    input  logic [DATA_WIDTH-1:0]   instr_rdata,
    input  logic [DATA_WIDTH-1:0]   data_addr,
    input  logic [DATA_WIDTH-1:0]   data_wdata,
    input  logic                    data_we,
    input  logic                    data_re,
    input  logic [DATA_WIDTH-1:0]   data_rdata,
    // Pipeline registers (if accessible)
    input  logic [DATA_WIDTH-1:0]   if_id_pc,
    input  logic [DATA_WIDTH-1:0]   if_id_instr,
    input  logic [DATA_WIDTH-1:0]   id_ex_pc,
    input  logic [DATA_WIDTH-1:0]   id_ex_rd1,
    input  logic [DATA_WIDTH-1:0]   id_ex_rd2,
    input  logic [DATA_WIDTH-1:0]   id_ex_imm,
    input  logic [4:0]              id_ex_rd,
    input  logic                    id_ex_reg_write,
    input  logic                    id_ex_mem_read,
    input  logic                    id_ex_mem_write,
    input  logic [DATA_WIDTH-1:0]   ex_mem_alu_result,
    input  logic [4:0]              ex_mem_rd,
    input  logic                    ex_mem_reg_write,
    input  logic                    ex_mem_mem_read,
    input  logic                    ex_mem_mem_write,
    input  logic [DATA_WIDTH-1:0]   mem_wb_alu_result,
    input  logic [4:0]              mem_wb_rd,
    input  logic                    mem_wb_reg_write,
    input  logic [DATA_WIDTH-1:0]   wb_data,
    // Hazard signals
    input  logic                    stall,
    input  logic                    flush
);

    // Instruction tracking
    typedef struct packed {
        logic [31:0] pc;
        logic [31:0] instr;
        logic        valid;
    } instr_trace_t;

    instr_trace_t instr_history [0:1023];
    int instr_history_ptr;

    // Pipeline stage tracking
    typedef enum logic [2:0] {
        S_IF  = 3'd0,
        S_ID  = 3'd1,
        S_EX  = 3'd2,
        S_MEM = 3'd3,
        S_WB  = 3'd4
    } stage_t;

    // Instruction counters
    int total_instructions;
    int arithmetic_instrs;
    int logical_instrs;
    int shift_instrs;
    int load_instrs;
    int store_instrs;
    int branch_instrs;
    int jump_instrs;
    int immediate_instrs;
    
    // Hazard statistics
    int load_use_hazards;
    int control_hazards;
    int data_hazards;
    int stall_cycles;
    int flush_cycles;

    // Forwarding statistics
    int forward_ex_ex;
    int forward_ex_mem;
    int forward_mem_wb;

    // Branch prediction (if any)
    int branches_taken;
    int branches_not_taken;
    int branches_mispredicted;

    // Register file tracking
    logic [31:0] reg_file [0:31];
    
    initial begin
        instr_history_ptr = 0;
        total_instructions = 0;
        arithmetic_instrs = 0;
        logical_instrs = 0;
        shift_instrs = 0;
        load_instrs = 0;
        store_instrs = 0;
        branch_instrs = 0;
        jump_instrs = 0;
        immediate_instrs = 0;
        load_use_hazards = 0;
        control_hazards = 0;
        data_hazards = 0;
        stall_cycles = 0;
        flush_cycles = 0;
        forward_ex_ex = 0;
        forward_ex_mem = 0;
        forward_mem_wb = 0;
        branches_taken = 0;
        branches_not_taken = 0;
        branches_mispredicted = 0;
        for (int i = 0; i < 32; i++) reg_file[i] = 32'h0;
    end

    // Instruction decode helper
    function automatic logic [6:0] get_opcode(input logic [31:0] instr);
        return instr[6:0];
    endfunction

    function automatic logic [2:0] get_funct3(input logic [31:0] instr);
        return instr[14:12];
    endfunction

    function automatic logic [6:0] get_funct7(input logic [31:0] instr);
        return instr[31:25];
    endfunction

    function automatic logic [4:0] get_rd(input logic [31:0] instr);
        return instr[11:7];
    endfunction

    function automatic logic [4:0] get_rs1(input logic [31:0] instr);
        return instr[19:15];
    endfunction

    function automatic logic [4:0] get_rs2(input logic [31:0] instr);
        return instr[24:20];
    endfunction

    // Instruction classification
    function automatic logic is_arithmetic(input logic [31:0] instr);
        logic [6:0] opcode;
        logic [2:0] f3;
        logic [6:0] f7;
        opcode = get_opcode(instr);
        f3 = get_funct3(instr);
        f7 = get_funct7(instr);
        return (opcode == 7'b0110011) && (f3 == 3'b000 || f3 == 3'b001 || f3 == 3'b010 || f3 == 3'b011 || f3 == 3'b100 || f3 == 3'b101 || f3 == 3'b110 || f3 == 3'b111);
    endfunction

    function automatic logic is_logical(input logic [31:0] instr);
        logic [6:0] opcode;
        logic [2:0] f3;
        logic [6:0] f7;
        opcode = get_opcode(instr);
        f3 = get_funct3(instr);
        f7 = get_funct7(instr);
        return (opcode == 7'b0110011) && (f3 == 3'b100 || f3 == 3'b110 || f3 == 3'b111) && (f7 == 7'b0000000 || f7 == 7'b0100000);
    endfunction

    function automatic logic is_shift(input logic [31:0] instr);
        logic [6:0] opcode;
        logic [2:0] f3;
        opcode = get_opcode(instr);
        f3 = get_funct3(instr);
        return (opcode == 7'b0110011) && (f3 == 3'b001 || f3 == 3'b101);
    endfunction

    function automatic logic is_load(input logic [31:0] instr);
        return get_opcode(instr) == 7'b0000011;
    endfunction

    function automatic logic is_store(input logic [31:0] instr);
        return get_opcode(instr) == 7'b0100011;
    endfunction

    function automatic logic is_branch(input logic [31:0] instr);
        return get_opcode(instr) == 7'b1100011;
    endfunction

    function automatic logic is_jump(input logic [31:0] instr);
        return (get_opcode(instr) == 7'b1101111) || (get_opcode(instr) == 7'b1100111);
    endfunction

    function automatic logic is_immediate(input logic [31:0] instr);
        return (get_opcode(instr) == 7'b0010011) || (get_opcode(instr) == 7'b0110111) || (get_opcode(instr) == 7'b0010111);
    endfunction

    // Monitor logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset handled by initial block
        end else begin
            // Track instruction fetch
            if (!stall && !flush) begin
                instr_history_ptr <= (instr_history_ptr + 1) % 1024;
                
                total_instructions++;
                
                // Classify instruction
                if (is_arithmetic(instr_rdata)) arithmetic_instrs++;
                else if (is_logical(instr_rdata)) logical_instrs++;
                else if (is_shift(instr_rdata)) shift_instrs++;
                else if (is_load(instr_rdata)) load_instrs++;
                else if (is_store(instr_rdata)) store_instrs++;
                else if (is_branch(instr_rdata)) branch_instrs++;
                else if (is_jump(instr_rdata)) jump_instrs++;
                else if (is_immediate(instr_rdata)) immediate_instrs++;
            end

            // Track hazards
            if (stall) begin
                stall_cycles++;
                if (id_ex_mem_read) load_use_hazards++;
            end

            if (flush) begin
                flush_cycles++;
                control_hazards++;
            end

            // Track forwarding (simplified - would need actual forward signals)
            // This is a placeholder - real implementation would check forward signals

            // Track branches
            if (is_branch(instr) && !stall && !flush) begin
                // Would need to check actual branch outcome
                branches_taken++;
            end

            // Track register writes
            if (reg_write) begin
                reg_file[mem_wb_rd] <= wb_data;
            end
        end
    end

    // Report generation
    task automatic generate_report();
        $display("\n=== CPU Monitor Report ===");
        $display("Total Instructions Executed: %0d", total_instructions);
        $display("Arithmetic Instructions:     %0d", arithmetic_instrs);
        $display("Logical Instructions:        %0d", logical_instrs);
        $display("Shift Instructions:          %0d", shift_instrs);
        $display("Load Instructions:           %0d", load_instrs);
        $display("Store Instructions:          %0d", store_instrs);
        $display("Branch Instructions:         %0d", branch_instrs);
        $display("Jump Instructions:           %0d", jump_instrs);
        $display("Immediate Instructions:      %0d", immediate_instrs);
        $display("");
        $display("Hazard Statistics:");
        $display("  Load-Use Hazards:   %0d", load_use_hazards);
        $display("  Control Hazards:    %0d", control_hazards);
        $display("  Data Hazards:       %0d", data_hazards);
        $display("  Stall Cycles:       %0d", stall_cycles);
        $display("  Flush Cycles:       %0d", flush_cycles);
        $display("");
        $display("Forwarding Statistics:");
        $display("  EX->EX:    %0d", forward_ex_ex);
        $display("  EX->MEM:   %0d", forward_ex_mem);
        $display("  MEM->WB:   %0d", forward_mem_wb);
        $display("");
        $display("Branch Statistics:");
        $display("  Taken:         %0d", branches_taken);
        $display("  Not Taken:     %0d", branches_not_taken);
        $display("  Mispredicted:  %0d", branches_mispredicted);
        $display("=============================");
    endtask

    // Coverage collection (simplified)
    // In a real environment, this would use SystemVerilog covergroups

endmodule