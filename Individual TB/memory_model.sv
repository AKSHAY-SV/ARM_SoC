`timescale 1ns / 1ps

module memory_model #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int DEPTH = 1024
)(
    input  logic                    clk,
    input  logic                    rst_n,
    // Memory Interface
    input  logic                    we,
    input  logic                    re,
    input  logic [1:0]              mem_size,
    input  logic                    mem_signed,
    input  logic [ADDR_WIDTH-1:0]   addr,
    input  logic [DATA_WIDTH-1:0]   wd,
    output logic [DATA_WIDTH-1:0]   rd
);

    logic [7:0] mem [0:DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 8'h00;
    end

    // Synchronous Write
    always_ff @(posedge clk) begin
        if (we) begin
            case (mem_size)
                2'b00: begin  // Byte
                    mem[addr[9:0]] <= wd[7:0];
                end
                2'b01: begin  // Half-word
                    mem[addr[9:0]]   <= wd[7:0];
                    mem[addr[9:0]+1] <= wd[15:8];
                end
                2'b10: begin  // Word
                    mem[addr[9:0]]   <= wd[7:0];
                    mem[addr[9:0]+1] <= wd[15:8];
                    mem[addr[9:0]+2] <= wd[23:16];
                    mem[addr[9:0]+3] <= wd[31:24];
                end
                default: ;
            endcase
        end
    end

    // Combinational Read
    always_comb begin
        if (re) begin
            case (mem_size)
                2'b00: begin  // Byte
                    rd = mem_signed ? {{24{mem[addr[9:0]][7]}}, mem[addr[9:0]]}
                                    : {24'h000000, mem[addr[9:0]]};
                end
                2'b01: begin  // Half-word
                    rd = mem_signed ? {{16{mem[addr[9:0]+1][7]}}, mem[addr[9:0]+1], mem[addr[9:0]]}
                                    : {16'h0000, mem[addr[9:0]+1], mem[addr[9:0]]};
                end
                2'b10: begin  // Word
                    rd = {mem[addr[9:0]+3], mem[addr[9:0]+2], mem[addr[9:0]+1], mem[addr[9:0]]};
                end
                default: rd = 32'h00000000;
            endcase
        end else begin
            rd = 32'h00000000;
        end
    end

    // Backdoor access for testbench
    task automatic mem_write(input logic [31:0] addr, input logic [31:0] data, input logic [1:0] size);
        case (size)
            2'b00: mem[addr[9:0]] = data[7:0];
            2'b01: begin
                mem[addr[9:0]] = data[7:0];
                mem[addr[9:0]+1] = data[15:8];
            end
            2'b10: begin
                mem[addr[9:0]] = data[7:0];
                mem[addr[9:0]+1] = data[15:8];
                mem[addr[9:0]+2] = data[23:16];
                mem[addr[9:0]+3] = data[31:24];
            end
        endcase
    endtask

    function automatic logic [31:0] mem_read(input logic [31:0] addr, input logic [1:0] size, input logic signed_);
        logic [31:0] rdata;
        case (size)
            2'b00: rdata = signed_ ? {{24{mem[addr[9:0]][7]}}, mem[addr[9:0]]} : {24'h000000, mem[addr[9:0]]};
            2'b01: rdata = signed_ ? {{16{mem[addr[9:0]+1][7]}}, mem[addr[9:0]+1], mem[addr[9:0]]} : {16'h0000, mem[addr[9:0]+1], mem[addr[9:0]]};
            2'b10: rdata = {mem[addr[9:0]+3], mem[addr[9:0]+2], mem[addr[9:0]+1], mem[addr[9:0]]};
            default: rdata = 32'h00000000;
        endcase
        return rdata;
    endfunction

endmodule