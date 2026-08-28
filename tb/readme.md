
---

# 9. `tb/readme.md`

```md
# RTL Testbenches

This folder contains Verilog-based testbenches used for directed testing of the processor and integrated SoC.

These testbenches provide focused simulation environments and complement the more comprehensive SystemVerilog verification infrastructure available in the [`Individual TB`](../Individual%20TB) directory.

---

## Contents

### `tb.v`

Main directed processor and ISA regression testbench.

The testbench loads instructions into memory and verifies the expected processor behavior.

The regression checks functionality such as:

- Arithmetic operations
- Logical operations
- Load operations
- Store operations
- Branch instructions
- Jump instructions
- Multiply operations
- Divide operations
- MAC operations
- Datapath functionality

The testbench uses self-checking mechanisms to report PASS or FAIL results.

---

### `tb_top.v`

Basic processor-level top-module testbench.

The testbench:

- Generates the system clock
- Generates reset
- Instantiates the processor top module
- Generates a VCD waveform
- Monitors important CPU signals

Typical signals observed include:

- Program Counter
- Current instruction
- ALU result
- Register-write activity

This testbench is useful for quick debugging and waveform analysis.

---

### `tb_soc_final.v`

Integrated SoC testbench.

Instantiates the complete `soc_top` design and performs system-level testing.

The testbench provides:

- Clock generation
- Reset generation
- GPIO pad-level modeling
- UART input stimulus
- SoC integration checks

The GPIO behavior is modeled externally to match the synthesizable split GPIO interface used by the SoC.

---

# Testbench Hierarchy

```text
                    RTL Testbenches
                          |
          +---------------+---------------+
          |               |               |
          v               v               v
        tb.v          tb_top.v       tb_soc_final.v
          |               |               |
          v               v               v
    ISA Regression   CPU Debugging    SoC Integration
