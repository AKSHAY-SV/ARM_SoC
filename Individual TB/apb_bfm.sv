`timescale 1ns / 1ps

module apb_bfm #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
)(
    input  logic                    pclk,
    input  logic                    presetn,
    // APB Master Interface
    output logic                    m_psel,
    output logic                    m_penable,
    output logic                    m_pwrite,
    output logic [ADDR_WIDTH-1:0]   m_paddr,
    output logic [DATA_WIDTH-1:0]   m_pwdata,
    input  logic [DATA_WIDTH-1:0]   m_prdata,
    input  logic                    m_pready,
    // BFM Control
    input  logic                    start_transaction,
    input  logic                    write_not_read,
    input  logic [ADDR_WIDTH-1:0]   transaction_addr,
    input  logic [DATA_WIDTH-1:0]   transaction_wdata,
    output logic [DATA_WIDTH-1:0]   transaction_rdata,
    output logic                    transaction_done,
    output logic                    transaction_error
);

    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        SETUP   = 2'b01,
        ACCESS  = 2'b10
    } state_t;

    state_t current_state, next_state;
    
    logic [ADDR_WIDTH-1:0] addr_reg;
    logic [DATA_WIDTH-1:0] wdata_reg;
    logic                  write_reg;
    
    always_ff @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            current_state <= IDLE;
            m_psel <= 1'b0;
            m_penable <= 1'b0;
            m_pwrite <= 1'b0;
            m_paddr <= '0;
            m_pwdata <= '0;
            transaction_done <= 1'b0;
            transaction_error <= 1'b0;
            addr_reg <= '0;
            wdata_reg <= '0;
            write_reg <= 1'b0;
        end else begin
            current_state <= next_state;
            transaction_done <= 1'b0;
            
            case (current_state)
                IDLE: begin
                    m_psel <= 1'b0;
                    m_penable <= 1'b0;
                    if (start_transaction) begin
                        addr_reg <= transaction_addr;
                        wdata_reg <= transaction_wdata;
                        write_reg <= write_not_read;
                        m_psel <= 1'b1;
                        m_pwrite <= write_not_read;
                        m_paddr <= transaction_addr;
                        m_pwdata <= transaction_wdata;
                        next_state <= SETUP;
                    end
                end
                
                SETUP: begin
                    m_penable <= 1'b1;
                    next_state <= ACCESS;
                end
                
                ACCESS: begin
                    if (m_pready) begin
                        transaction_done <= 1'b1;
                        if (!write_reg) begin
                            transaction_rdata <= m_prdata;
                        end
                        m_psel <= 1'b0;
                        m_penable <= 1'b0;
                        next_state <= IDLE;
                    end else begin
                        // Wait for ready
                        next_state <= ACCESS;
                    end
                end
            endcase
        end
    end

endmodule