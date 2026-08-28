// ==============================================================================
// FILE: cpu_constants.vh
// DESCRIPTION: Global parameters and macros for the ARM Cortex-style core.
//              Contains ALU operations, branch condition codes, and AHB states.
// ==============================================================================

`ifndef CPU_CONSTANTS_VH
`define CPU_CONSTANTS_VH

// ==============================================================================
// Core Architecture Parameters
// ==============================================================================
`define DATA_WIDTH      32
`define ADDR_WIDTH      32
`define REG_COUNT       16    // ARM Standard: R0-R12 (GPRs), R13(SP), R14(LR), R15(PC)

// ==============================================================================
// ALU Operations (ARM V6-M / V7-M Subset)
// ==============================================================================
`define ALU_ADD         5'b00000
`define ALU_SUB         5'b00001
`define ALU_ADC         5'b00010  // Add with Carry
`define ALU_SBC         5'b00011  // Subtract with Carry
`define ALU_AND         5'b00100
`define ALU_ORR         5'b00101
`define ALU_EOR         5'b00110  // Exclusive OR
`define ALU_BIC         5'b00111  // Bit Clear (AND NOT)
`define ALU_MOV         5'b01000  // Move
`define ALU_MVN         5'b01001  // Move NOT
`define ALU_CMP         5'b01010  // Compare (Subtract, update flags, no writeback)
`define ALU_TST         5'b01011  // Test (AND, update flags, no writeback)
`define ALU_LSL         5'b01100  // Logical Shift Left
`define ALU_LSR         5'b01101  // Logical Shift Right
`define ALU_ASR         5'b01110  // Arithmetic Shift Right
`define ALU_ROR         5'b01111  // Rotate Right
`define ALU_MUL         5'b10000  // Multiply

// ==============================================================================
// Condition Codes (ARM Architecture)
// ==============================================================================
// Evaluated against the APSR (N, Z, C, V flags)
`define COND_EQ         4'b0000   // Equal                      (Z == 1)
`define COND_NE         4'b0001   // Not Equal                  (Z == 0)
`define COND_CS         4'b0010   // Carry Set / Unsigned >=    (C == 1)
`define COND_CC         4'b0011   // Carry Clear / Unsigned <   (C == 0)
`define COND_MI         4'b0100   // Minus / Negative           (N == 1)
`define COND_PL         4'b0101   // Plus / Positive or Zero    (N == 0)
`define COND_VS         4'b0110   // Overflow Set               (V == 1)
`define COND_VC         4'b0111   // Overflow Clear             (V == 0)
`define COND_HI         4'b1000   // Unsigned Higher            (C == 1 & Z == 0)
`define COND_LS         4'b1001   // Unsigned Lower or Same     (C == 0 | Z == 1)
`define COND_GE         4'b1010   // Signed >=                  (N == V)
`define COND_LT         4'b1011   // Signed <                   (N != V)
`define COND_GT         4'b1100   // Signed >                   (Z == 0 & N == V)
`define COND_LE         4'b1101   // Signed <=                  (Z == 1 | N != V)
`define COND_AL         4'b1110   // Always                     (Unconditional)

// ==============================================================================
// AMBA AHB-Lite Constants
// ==============================================================================
// HTRANS (Transfer Type)
`define HTRANS_IDLE     2'b00
`define HTRANS_BUSY     2'b01
`define HTRANS_NONSEQ   2'b10
`define HTRANS_SEQ      2'b11

// HSIZE (Transfer Size)
`define HSIZE_BYTE      3'b000    // 8-bit
`define HSIZE_HALF      3'b001    // 16-bit
`define HSIZE_WORD      3'b010    // 32-bit

// HBURST (Burst Type)
`define HBURST_SINGLE   3'b000

// HRESP (Transfer Response)
`define HRESP_OKAY      1'b0
`define HRESP_ERROR     1'b1

`endif // CPU_CONSTANTS_VH
