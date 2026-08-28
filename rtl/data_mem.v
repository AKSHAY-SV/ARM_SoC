`timescale 1ns / 1ps
module data_mem (
    input  wire        clk,
    input  wire        we,         
    input  wire        re,          
    input  wire [1:0]  mem_size,    
    input  wire        mem_signed, 
    input  wire [31:0] addr,
    input  wire [31:0] wd,          
    output reg  [31:0] rd           
);

    reg [7:0] mem [0:1023]; 
    integer i;
    
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = 8'h00;
    end
 
    // Synchronous Write Logic Path
    always @(posedge clk) begin
        if (we) begin
            case (mem_size)
                2'b00: begin  
                    mem[addr[9:0]] <= wd[7:0];
                end
                2'b01: begin  
                    mem[addr[9:0]]   <= wd[7:0];
                    mem[addr[9:0]+1] <= wd[15:8];
                end
                2'b10: begin 
                    mem[addr[9:0]]   <= wd[7:0];
                    mem[addr[9:0]+1] <= wd[15:8];
                    mem[addr[9:0]+2] <= wd[23:16];
                    mem[addr[9:0]+3] <= wd[31:24];
                end
                default: ;
            endcase
        end
    end
 
    // Gated Combinational Read Logic Array Block
    always @(*) begin
        if (re) begin
            case (mem_size)
                2'b00: begin  
                    rd = mem_signed ? {{24{mem[addr[9:0]][7]}}, mem[addr[9:0]]}
                                    : {24'h000000, mem[addr[9:0]]};
                end
                2'b01: begin  
                    rd = mem_signed ? {{16{mem[addr[9:0]+1][7]}}, mem[addr[9:0]+1], mem[addr[9:0]]}
                                    : {16'h0000, mem[addr[9:0]+1], mem[addr[9:0]]};
                end
                2'b10: begin  
                    rd = {mem[addr[9:0]+3], mem[addr[9:0]+2], mem[addr[9:0]+1], mem[addr[9:0]]};
                end
                default: rd = 32'h00000000;
            endcase
        end else begin
            rd = 32'h00000000; // Drive safe neutral constants when deselected
        end
    end
endmodule
