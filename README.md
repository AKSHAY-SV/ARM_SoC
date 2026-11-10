# ARM SoC

Register-Transfer Level (RTL) design of an ARM-based System on Chip (SoC),
written in Verilog. The project spans processor datapath and control,
instruction/data memory, address decoding and bus interconnect, APB peripherals
(GPIO, UART, SPI, Timer), a PLIC-style interrupt controller, top-level SoC
integration, RTL simulation and verification, synthesis, physical design
(floorplan, placement, CTS, routing), physical verification (DRC/LVS/antenna),
and GDSII layout generation.

The implementation follows a complete RTL-to-GDSII ASIC flow:

```text
Verilog RTL
     |
     v
Functional Verification (tb/, Individual TB/)
     |
     v
Synthesis (reports/synthesis.txt)
     |
     v
Floorplanning (Floorplan/, Floorplan Components/)
     |
     v
Power Grid Generation (reports/power_grid.txt)
     |
     v
Standard Cell Placement (reports/placement.txt)
     |
     v
Clock Tree Synthesis (reports/cts.txt)
     |
     v
Global and Detailed Routing (reports/routing.txt)
     |
     v
Static Timing Analysis (reports/timing.txt, setup_timing.txt, hold_timing.txt)
     |
     v
Physical Verification (reports/drc.txt, lvs.txt, antenna.txt)
     |
     v
GDSII Generation (GDSII/)
```

## Project Layout

| Folder | Description | Details |
|--------|-------------|---------|
| [`rtl/`](rtl/) | Complete Verilog RTL source for the processor, memories, bus, peripherals, and SoC integration | [`rtl/readme.md`](rtl/readme.md) |
| [`tb/`](tb/) | Verilog directed testbenches for processor and SoC testing | [`tb/readme.md`](tb/readme.md) |
| [`Individual TB/`](Individual%20TB/) | SystemVerilog verification environment (BFMs, scoreboard, coverage, monitors, Makefile) | [`Individual TB/readme.md`](Individual%20TB/readme.md) |
| [`Sim_Logs/`](Sim_Logs/) | Textual simulation logs (PASS/FAIL, compiler output, regression results) | [`Sim_Logs/readme.md`](Sim_Logs/readme.md) |
| [`Simultation/`](Simultation/) | Simulation screenshots demonstrating pipeline, APB, UART, SPI, and full-SoC operation | [`Simultation/readme.md`](Simultation/readme.md) |
| [`VCD Files/`](VCD%20Files/) | Value Change Dump waveform files for GTKWave | [`VCD Files/readme.md`](VCD%20Files/readme.md) |
| [`reports/`](reports/) | Synthesis, timing, physical-design, power, and physical-verification signoff reports | [`reports/readme.md`](reports/readme.md) |
| [`Floorplan/`](Floorplan/) | Top-level floorplan and placement images | [`Floorplan/readme.md`](Floorplan/readme.md) |
| [`Floorplan Components/`](Floorplan%20Components/) | Metal-layer, via, and power/ground layout views | [`Floorplan Components/readme.md`](Floorplan%20Components/readme.md) |
| [`GDSII/`](GDSII/) | Final GDSII physical-layout visualizations | [`GDSII/readme.md`](GDSII/readme.md) |

Each subfolder contains its own `readme.md` describing its contents in detail.

## Top-Level RTL Modules

| Module | Description |
|--------|-------------|
| `soc_top.v` | Complete integrated System-on-Chip top level |
| `top.v` | Processor-level top module for standalone debugging |
| `arm_processor.v` | ARM/Thumb processor microarchitecture |
| `Data_Path.v` | Pipelined processor datapath (fetch → writeback) |
| `control_unit.v` | Main instruction decode and control generation |
| `pc.v` | Program counter |
| `reg_file.v` | 32 × 32-bit general-purpose register file |
| `alu.v` | Arithmetic and logic unit |
| `mac_unit.v` / `multiplier.v` | Multiply and multiply-accumulate units |
| `branch_unit.v` | Branch and control-flow resolution |
| `barrel_shifter.v` | Logical and arithmetic shifting |
| `imm_gen.v` | Immediate-value generator |
| `execute_stage.v` / `writeback_stage.v` | ARM/Thumb execution and writeback stages |
| `apsr.v` | Application Program Status Register (condition flags) |
| `cpu_constants.vh` | Shared processor constants and opcode macros |
| `inst_mem.v` / `data_mem.v` | Instruction and data memory |
| `rom.v` / `ram.v` | ROM and RAM storage |
| `memory_interface.v` | Processor-to-memory interface |
| `address_decoder.v` / `axi_decoder.v` | Memory/peripheral address decoding |
| `bus_controller.v` | Bus transaction control |
| `ahb_master.v` | AHB/AHB-Lite master interface |
| `apb_subsystem.v` / `apb_interconnect.v` | APB subsystem wrapper and interconnect |
| `gpio_apb.v` | APB GPIO peripheral |
| `timer_apb.v` | APB timer peripheral |
| `spi_master_apb.v` | APB SPI master peripheral |
| `plic_simple.v` | Simplified PLIC interrupt controller |
| `apb_uart_wrapper.v` / `apb_uart.v` / `uart_regs.v` / `uart_top.v` / `uart_final.v` | UART peripheral modules |
| `baud_gen.v` | UART baud-rate generator |
| `uart_tx.v` / `uart_rx.v` | UART transmitter and receiver |
| `icg.v` / `reset_sync.v` | Clock gating and reset synchronization |
| `firmware.hex` / `boot_rom.hex` | Firmware and boot-ROM initialization images |

## Simulation and Verification

### Directed testbenches (`tb/`)
- `tb.v` — Main processor / ISA regression testbench (self-checking PASS/FAIL)
- `tb_top.v` — Processor-level top-module testbench with VCD dump
- `tb_soc_final.v` — Integrated SoC testbench with GPIO, UART, and integration checks

### SystemVerilog verification environment (`Individual TB/`)
- `soc_tb.sv` — Primary integrated SoC verification testbench
- `apb_bfm.sv`, `uart_bfm.sv`, `spi_bfm.sv` — Bus functional models
- `scoreboard_apb.sv` — APB transaction scoreboard
- `cpu_monitor.sv` — CPU execution / pipeline monitor
- `coverage_model.sv` — Functional coverage model
- `memory_model.sv` — Parameterized byte-addressable memory model
- `boot_rom.hex` — Boot ROM image for verification
- `Makefile` — Build and run the verification environment
- `regression.sh` — Regression automation script

Run the directed regression:
```bash
cd tb
iverilog -o tb_out tb.v rtl/*.v
vvp tb_out
```

Run the SystemVerilog verification:
```bash
cd "Individual TB"
make
```

Waveforms are written to `VCD Files/` and logs to `Sim_Logs/`. Open VCD dumps with
GTKWave:

```bash
gtkwave "VCD Files/soc_tb.vcd"
```

## Reports

The `reports/` folder contains signoff documentation for the full implementation:

- `verification_report.md` — Functional verification summary
- `synthesis.txt` — RTL synthesis report
- `floorplan.txt`, `placement.txt`, `cts.txt`, `routing.txt` — Physical design
- `timing.txt`, `setup_timing.txt`, `hold_timing.txt`, `critical_paths.txt` — Timing
- `power_grid.txt`, `ir_drop.txt`, `thermal.txt` — Power and thermal
- `drc.txt`, `lvs.txt`, `antenna.txt` — Physical verification
- `gdsii.txt` — GDSII stream-out
- `final_verification_summary.txt` — Consolidated results
- `rtl_simulation.txt`, `rtl_verification.txt`, `functional_coverage.txt` — Verification

See [`reports/readme.md`](reports/readme.md) for a recommended reading order.

## Physical Design

- `Floorplan/` — Top-level floorplan and post-placement views
- `Floorplan Components/` — Metal layers M1–M5, vias, VGND/VPWR power grids
- `GDSII/` — Final GDSII layout visualizations

## License

See the project folder for license details, if present.
