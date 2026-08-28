module axi_decoder(

    input  [31:0] addr,

    output rom_sel,
    output ram_sel,
    output apb_sel

);

assign rom_sel =
    (addr[31:28] == 4'h0);

assign ram_sel =
    (addr[31:28] == 4'h1);

assign apb_sel =
    (addr[31:28] == 4'h4);

endmodule	

