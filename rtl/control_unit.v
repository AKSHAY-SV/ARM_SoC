// ==============================================================================
// FILE: control_unit.v
// DESCRIPTION: RV32IM combinational main decoder. Generates datapath control
//              signals and the internal alu_ctrl field from opcode/funct3/funct7.
// ==============================================================================
`timescale 1ns / 1ps

module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg        reg_write,
    output reg        alu_src,
    output reg [1:0]  alu_op,
    output reg        mem_write,
    output reg        mem_read,
    output reg        mem_to_reg,
    output reg        branch,
    output reg        jump,
    output reg        jalr,
    output reg [1:0]  mem_size,
    output reg        mem_signed,
    output reg        lui,
    output reg        auipc,
    output reg        mac_en,
    output reg        mac_clr,

    output reg [4:0]  alu_ctrl
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

    wire is_m_ext = (opcode == OP_R) && (funct7 == 7'b0000001);

    always @(*) begin
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        alu_op     = 2'b00;
        mem_write  = 1'b0;
        mem_read   = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        jalr       = 1'b0;
        mem_size   = 2'b10;
        mem_signed = 1'b1;
        lui        = 1'b0;
        auipc      = 1'b0;
        mac_en     = 1'b0;
        mac_clr    = 1'b0;

        case (opcode)
            OP_R: begin
                reg_write = 1'b1;
                alu_op    = is_m_ext ? 2'b00 : 2'b10;
            end
            OP_I_ALU: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b10;
            end
            OP_LOAD: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                mem_size   = (funct3[1:0] == 2'b00) ? 2'b00 :
                             (funct3[1:0] == 2'b01) ? 2'b01 : 2'b10;
                mem_signed = ~funct3[2];
            end
            OP_STORE: begin
                alu_src   = 1'b1;
                mem_write = 1'b1;
                mem_size  = (funct3[1:0] == 2'b00) ? 2'b00 :
                            (funct3[1:0] == 2'b01) ? 2'b01 : 2'b10;
            end
            OP_BRANCH: begin
                branch = 1'b1;
                alu_op = 2'b01;
            end
            OP_JAL:  begin reg_write = 1'b1; jump = 1'b1; end
            OP_JALR: begin reg_write = 1'b1; alu_src = 1'b1; jalr = 1'b1; end
            OP_LUI:  begin reg_write = 1'b1; lui  = 1'b1; end
            OP_AUIPC:begin reg_write = 1'b1; alu_src = 1'b1; auipc= 1'b1; end
            OP_CUSTOM: begin
                if (funct3 == 3'b000) begin
                    reg_write = 1'b1;
                    mac_en    = 1'b1;
                end else if (funct3 == 3'b001) begin
                    mac_clr   = 1'b1;
                end
            end
            default: ;
        endcase
    end

    always @(*) begin
        if (is_m_ext) begin
            case (funct3)
                3'b000: alu_ctrl = 5'b01011;
                3'b001: alu_ctrl = 5'b01100;
                3'b011: alu_ctrl = 5'b01101;
                3'b010: alu_ctrl = 5'b01110;
                3'b100: alu_ctrl = 5'b01111;
                3'b101: alu_ctrl = 5'b10000;
                3'b110: alu_ctrl = 5'b10001;
                3'b111: alu_ctrl = 5'b10010;
                default: alu_ctrl = 5'b00000;
            endcase
        end else if (opcode == OP_CUSTOM && funct3 == 3'b000) begin
            alu_ctrl = 5'b10011;
        end else begin
            case (alu_op)
                2'b00: alu_ctrl = 5'b00000;
                2'b11: alu_ctrl = 5'b01010;
                2'b01: begin
                    case (funct3)
                        3'b000, 3'b001: alu_ctrl = 5'b00001;
                        3'b100, 3'b101: alu_ctrl = 5'b01000;
                        3'b110, 3'b111: alu_ctrl = 5'b01001;
                        default:        alu_ctrl = 5'b00001;
                    endcase
                end
                2'b10: begin
                    case (funct3)
                        3'b000: alu_ctrl = ((opcode == OP_R) && funct7[5]) ? 5'b00001 : 5'b00000;
                        3'b001: alu_ctrl = 5'b00101;
                        3'b010: alu_ctrl = 5'b01000;
                        3'b011: alu_ctrl = 5'b01001;
                        3'b100: alu_ctrl = 5'b00100;
                        3'b101: alu_ctrl = funct7[5] ? 5'b00111 : 5'b00110;
                        3'b110: alu_ctrl = 5'b00011;
                        3'b111: alu_ctrl = 5'b00010;
                        default: alu_ctrl = 5'b00000;
                    endcase
                end
                default: alu_ctrl = 5'b00000;
            endcase
        end
    end
endmodule
