module rom #(
    parameter DEPTH = 256
)(
    input           clk,
    input  [31:0]   addr,
    output reg [31:0] rdata
);

reg [31:0] mem [0:DEPTH-1];

initial begin
    $readmemh("firmware.hex", mem);
end

always @(posedge clk)
begin
    rdata <= mem[addr[31:2]];
end

endmodule
