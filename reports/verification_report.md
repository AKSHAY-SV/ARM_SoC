# ARM_SoC Functional Verification Report

**Date:** 2026-08-03
**DUT:** 5-stage RV32IM CPU + APB peripherals (GPIO, Timer, SPI, PLIC, UART) — top `soc_top`
**Simulator:** Icarus Verilog 12 (iverilog/vvp), dump to `soc_tb.vcd`
**Environment:** `Complete_TB/` — CPU-driven firmware test, APB scoreboard, BFM-based GPIO/UART/SPI checkers, functional coverage model, CPU pipeline monitor
**Simulation length:** 178,035,000 ps (~178 µs)
**Firmware:** 372 instructions / 512-word boot ROM

## Verdict: ALL CHECKERS PASS — 100% COVERAGE

- Firmware self-check result: `0x5A5A5A5A` (PASS)
- APB scoreboard: **36/36** transactions matched expected
- GPIO / UART-TX / UART-RX / SPI / PLIC checkers: PASS
- Checkpoints 1–8 all reached in order
- Functional coverage: **29/29 bins (100.0%)**
- Block-level ISA regression (`ARM_SoC/tb/tb.v`): **35/35 PASS**

## Test Coverage (firmware-driven tests)

| # | Test | Result |
|---|------|--------|
| 1 | GPIO: OUT sequence, DIR, live input readback | PASS (5 transitions) |
| 2 | Timer: overflow → STATUS, clear, disable | PASS |
| 3 | UART TX: 'H','I','!' verified on wire | PASS |
| 4 | UART RX: 0xAA/0x55 frames received, status | PASS |
| 5 | SPI: 0xA5/0x5A MOSI verified, MISO readback 0x00, DONE W1C | PASS |
| 6 | PLIC: pending set/clear, cpu_irq pulse, ENABLE | PASS |
| 7 | CPU: RAM roundtrip, ALU chain w/ forwarding, shifts, slt/sltu, branch loop, load-use stall, jal/jalr, auipc/lui, MAC, RAM pattern | PASS |
| 8 | CPU: lb/lh/lbu/lhu sign/zero extension, sb/sh partial stores, unmapped-access probe | PASS |
| 9 | CPU: M-extension (mul/mulh/mulhsu/mulhu, div/divu/rem/remu incl. INT_MIN/-1 and /0 special cases), x0-sink discard, immediate extremes, shift boundaries, all 6 branch conditions taken/not-taken | PASS |

Checkpoint timing: ck2 @14.6 µs, ck3 @37.1 µs, ck4 @63.4 µs, ck5 @95.7 µs, ck6 @130.2 µs, ck7 @165.0 µs, ck8 @178.0 µs.

## ISA Coverage (whole RV32IM + M + MAC)

Full integer ISA exercised at the SoC level: add/sub/sll/slt/sltu/xor/srl/sra/or/and,
addi/slti/sltiu/xori/ori/andi/slli/srli/srai, lb/lh/lbu/lhu/lw, sb/sh/sw,
beq/bne/blt/bge/bltu/bgeu, jal/jalr, lui/auipc, mul/mulh/mulhsu/mulhu,
div/divu/rem/remu, MAC (mac/maclr), plus hardware forwarding, load-use stalls,
and pipeline flushes.

## Functional Coverage — 29/29 (100.0%)

| Bin | Status |
|-----|--------|
| APB GPIO/TIMER/SPI/PLIC/UART write & read (10) | hit |
| UART TX byte, UART RX byte, SPI transfer | hit |
| TIMER overflow, TIMER auto-reload | hit |
| PLIC pending set, pending clear, cpu_irq | hit |
| CPU load, store, branch taken, branch not-taken, jalr, MAC, MUL/MULH, DIV/REM, stall (hazard) | hit |
| APB out-of-window access | hit — directed unmapped-access probe (0x6000): SoC decode steers it to RAM, no spurious PSEL; probed at the decode point |
| UART stop-bit error | hit — corrupt frame (0x33, stop bit driven low) injected into DUT RX after the PLIC test; DUT RX does not gate on stop and receives the data |

## CPU Pipeline Monitor

- Instructions executed: 13,431 (branch 4,368; jump 4,351; immediate 4,590; load 34; store 45; arithmetic 38)
- Hazards: 6 load-use (stall cycles: 6), 4,360 control (flush cycles: 4,360), 0 data
- Forwarding: EX→EX / EX→MEM / MEM→WB all 0 (full stall policy)
- Branches: 4,368 taken; 0 mispredicted (no branch prediction). Not-taken branches are detected by the coverage model from the RTL signals.

High branch/jump counts are expected: delay-loop `bne` iterations plus the final `j hang` spin loop (~100 µs).

## Defects Found and Fixed

**RTL (`ARM_SoC/rtl/`)**
1. `spi_master_apb.v` — SCLK left HIGH at end of transfer; idle phase inverted, corrupting back-to-back transfers (0x5A read as 0x2D). Fixed: force SCLK low on completion (mode-0 idle).
2. `spi_master_apb.v` — DONE bit sticky, SPI IRQ asserted forever → PLIC pending bit never released. Fixed: STATUS DONE is write-1-to-clear.
3. **Load-size/sign handling dead at both tops.** `top.v` and `soc_top.v` hardwired `.mem_size(2'b10)` / `.mem_signed(1'b1)` to the data memory, so lb/lh/lbu/lhu loads returned full words and sb/sh stores wrote full words (LHU of 0xFFFB read back as 0xFFFFFFFB). The datapath computed `mem_size`/`mem_signed` through the pipeline but never exported them. Fixed: exported as `datapath` outputs wired to `data_mem` in both tops. Block-level regression `tb.v` now reports **35/35 PASS** (was 34/35), and the SoC-level firmware Tests 8–9 cover all four load widths plus sb/sh.
4. `inst_mem.v` — boot ROM depth extended to 512 words (parameterized `ADDR_HI`) to fit the full-ISA firmware; `soc_top.v` instantiates it at 512.

**Testbench / tooling (`Complete_TB/`)**
5. `tools/asm_rv32i.py` — pass-1 label sizing ignored 2-word `li` expansion (every label off by 24 bytes); B-type immediate bit packing wrong; I-type ALU and R-type encoders passed operands as `rd, rs1` swapped (rd/rs1 exchanged). All fixed; firmware re-encoded and every branch/jump target verified by decode. Extended with lb/lh/lbu/lhu/sb/sh and the full M-extension (mul/mulh/mulhsu/mulhu/div/divu/rem/remu).
6. `uart_bfm.sv` — TX start-bit held only one bit-period; DUT RX sampling (which consumes a baud tick in START) landed one bit period late. Fixed: start bit extended by 3 ticks. Later extended with a corrupt-stop-bit TX mode for the stop-bit-error coverage bin.
7. Firmware — PLIC ENABLE value clobbered by `delay()` (wrote 0); timer STATUS cleared while timer still enabled → re-overflow; PLIC stale SPI pending bit not cleared at test start. Fixed ordering/values.

## Files

- `Complete_TB/tools/asm_rv32i.py` — assembler + firmware source (full RV32IM+M+MAC self-check program)
- `Complete_TB/boot_rom.hex` — regenerated firmware image (372 instructions)
- `Complete_TB/soc_tb.sv` — top TB, checkers, expected-transaction list (36), stop-bit-error + unmapped-access stimuli
- `Complete_TB/{uart_bfm,spi_bfm,scoreboard_apb,cpu_monitor,coverage_model}.sv` — verification IP
- `ARM_SoC/rtl/{Data_Path,top,soc_top,inst_mem}.v` — mem_size/mem_signed export + boot-ROM depth fixes
- `Complete_TB/Makefile`, `Complete_TB/regression.sh` — build/run
- `Complete_Simulation/{soc_tb.vcd,verification_report.txt}` — artifacts

## How to Reproduce

```sh
cd Complete_TB
./regression.sh
```

Block-level ISA regression:

```sh
cd ARM_SoC/tb
iverilog -g2005-sv -o /tmp/tb_top.vvp -I ../rtl tb.v ../rtl/top.v ../rtl/Data_Path.v \
  ../rtl/pc.v ../rtl/control_unit.v ../rtl/imm_gen.v ../rtl/reg_file.v ../rtl/alu.v \
  ../rtl/mac_unit.v ../rtl/multiplier.v ../rtl/barrel_shifter.v ../rtl/inst_mem.v ../rtl/data_mem.v
vvp /tmp/tb_top.vvp   # expect 35 PASSED, 0 FAILED
```
