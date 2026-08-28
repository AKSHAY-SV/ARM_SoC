`timescale 1ns / 1ps

module scoreboard_apb #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int MAX_TXN    = 128
)(
    input  logic                    clk,
    input  logic                    rst_n,
    // APB Monitor Interface
    input  logic                    m_psel,
    input  logic                    m_penable,
    input  logic                    m_pwrite,
    input  logic [ADDR_WIDTH-1:0]   m_paddr,
    input  logic [DATA_WIDTH-1:0]   m_pwdata,
    input  logic [DATA_WIDTH-1:0]   m_prdata,
    input  logic                    m_pready
);

    // Transaction record
    typedef struct packed {
        logic                   write;
        logic [ADDR_WIDTH-1:0]  addr;
        logic [DATA_WIDTH-1:0]  wdata;
        logic [DATA_WIDTH-1:0]  rdata;
        logic                   ready;
        logic                   rdata_check;
    } transaction_t;

    // FIFOs implemented as fixed arrays with head counters (iverilog has no
    // queue-of-struct support).
    transaction_t expected_queue [0:MAX_TXN-1];
    transaction_t actual_queue   [0:MAX_TXN-1];
    int expected_n;
    int actual_n;

    // Memory model for verification
    logic [DATA_WIDTH-1:0] memory [0:1023];

    // Capture actual transactions
    always_ff @(posedge clk) begin
        if (m_psel && m_penable && m_pready) begin
            transaction_t t;
            t.write  = m_pwrite;
            t.addr   = m_paddr;
            t.wdata  = m_pwdata;
            t.rdata  = m_prdata;
            t.ready  = m_pready;
            t.rdata_check = 1'b1;
            if (actual_n < MAX_TXN) begin
                actual_queue[actual_n] = t;
                actual_n++;
            end else begin
                $error("SCOREBOARD: actual transaction FIFO overflow");
            end
        end
    end

    // Expected transaction methods
    task automatic push_expected(input transaction_t t);
        if (expected_n < MAX_TXN) begin
            expected_queue[expected_n] = t;
            expected_n++;
        end else begin
            $error("SCOREBOARD: expected transaction FIFO overflow");
        end
    endtask

    task automatic expect_write(input logic [ADDR_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] data);
        transaction_t t;
        t.write = 1'b1;
        t.addr = addr;
        t.wdata = data;
        t.rdata = '0;
        t.ready = 1'b1;
        t.rdata_check = 1'b1;
        push_expected(t);
    endtask

    task automatic expect_read(input logic [ADDR_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] data);
        transaction_t t;
        t.write = 1'b0;
        t.addr = addr;
        t.wdata = '0;
        t.rdata = data;
        t.ready = 1'b1;
        t.rdata_check = 1'b1;
        push_expected(t);
    endtask

    // Read whose returned data is not deterministic (e.g. timer VALUE):
    // transaction type/address/order are still checked, data is not.
    task automatic expect_read_any(input logic [ADDR_WIDTH-1:0] addr);
        transaction_t t;
        t.write = 1'b0;
        t.addr = addr;
        t.wdata = '0;
        t.rdata = '0;
        t.ready = 1'b1;
        t.rdata_check = 1'b0;
        push_expected(t);
    endtask

    // Compare actual vs expected
    task automatic check_transactions();
        int mism = 0;
        int checked = 0;
        int n = (expected_n < actual_n) ? expected_n : actual_n;
        for (int i = 0; i < n; i++) begin
            transaction_t exp = expected_queue[i];
            transaction_t act = actual_queue[i];
            checked++;
            if (exp.write !== act.write) begin
                $error("SCOREBOARD: Write/Read mismatch. Exp: %b, Act: %b", exp.write, act.write);
                mism++;
            end
            if (exp.addr !== act.addr) begin
                $error("SCOREBOARD: Address mismatch. Exp: 0x%h, Act: 0x%h", exp.addr, act.addr);
                mism++;
            end
            if (exp.write) begin
                if (exp.wdata !== act.wdata) begin
                    $error("SCOREBOARD: Write data mismatch. Exp: 0x%h, Act: 0x%h", exp.wdata, act.wdata);
                    mism++;
                end
            end else if (exp.rdata_check) begin
                if (exp.rdata !== act.rdata) begin
                    $error("SCOREBOARD: Read data mismatch. Exp: 0x%h, Act: 0x%h", exp.rdata, act.rdata);
                    mism++;
                end
            end
            if (exp.ready !== act.ready) begin
                $error("SCOREBOARD: Ready mismatch. Exp: %b, Act: %b", exp.ready, act.ready);
                mism++;
            end
        end
        if (expected_n != actual_n) begin
            $error("SCOREBOARD: %0d expected and %0d actual transactions uncompared",
                   expected_n - n, actual_n - n);
            mism++;
        end
        if (mism == 0) begin
            $display("SCOREBOARD: PASS - all %0d APB transactions matched expected", checked);
        end else begin
            $error("SCOREBOARD: FAIL - %0d mismatch(es) out of %0d transactions", mism, checked);
        end
    endtask

    // Memory model for data memory
    task automatic mem_write(input logic [31:0] addr, input logic [31:0] data, input logic [1:0] size);
        case (size)
            2'b00: memory[addr[9:0]] = data[7:0];
            2'b01: begin
                memory[addr[9:0]] = data[7:0];
                memory[addr[9:0]+1] = data[15:8];
            end
            2'b10: begin
                memory[addr[9:0]] = data[7:0];
                memory[addr[9:0]+1] = data[15:8];
                memory[addr[9:0]+2] = data[23:16];
                memory[addr[9:0]+3] = data[31:24];
            end
        endcase
    endtask

    function automatic logic [31:0] mem_read(input logic [31:0] addr, input logic [1:0] size, input logic signed_);
        logic [31:0] rdata;
        case (size)
            2'b00: rdata = signed_ ? {{24{memory[addr[9:0]][7]}}, memory[addr[9:0]]} : {24'h0, memory[addr[9:0]]};
            2'b01: rdata = signed_ ? {{16{memory[addr[9:0]+1][7]}}, memory[addr[9:0]+1], memory[addr[9:0]]} : {16'h0, memory[addr[9:0]+1], memory[addr[9:0]]};
            2'b10: rdata = {memory[addr[9:0]+3], memory[addr[9:0]+2], memory[addr[9:0]+1], memory[addr[9:0]]};
            default: rdata = 32'h0;
        endcase
        return rdata;
    endfunction

endmodule
