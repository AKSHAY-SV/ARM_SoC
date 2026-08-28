module ram #(
    parameter DEPTH = 1024
)(
    input           clk,

    input           we,
    input  [31:0]   addr,
    input  [31:0]   wdata,

    output reg [31:0] rdata
);

reg [31:0] mem [0:DEPTH-1];

integer i;

initial begin
    for(i=0;i<DEPTH;i=i+1)
        mem[i] = 32'h0;
end

always @(posedge clk)
begin
	
    if(we)
        mem[addr[31:2]] <= wdata;

    rdata <= mem[addr[31:2]];

end

endmodule
