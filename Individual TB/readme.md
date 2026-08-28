
---

# 4. `Individual TB/readme.md`

```md
# Individual Testbench and Verification Environment

This folder contains the SystemVerilog-based verification infrastructure used to test the ARM SoC and its APB-connected peripherals.

The verification environment combines CPU-driven firmware execution with bus monitoring, protocol BFMs, scoreboarding, functional coverage, and pipeline monitoring.

---

## Contents

### `soc_tb.sv`

Main top-level SoC verification testbench.

The testbench:

- Generates clock and reset
- Instantiates the SoC DUT
- Executes the firmware program
- Monitors CPU activity
- Checks APB transactions
- Verifies GPIO behavior
- Exercises UART communication
- Exercises SPI communication
- Checks interrupt behavior
- Connects functional coverage
- Generates simulation results

This is the primary integrated verification environment.

---

### `apb_bfm.sv`

APB Bus Functional Model.

Generates controlled APB transactions following the APB protocol.

The BFM handles:

- APB setup phase
- APB access phase
- Read transactions
- Write transactions
- Address generation
- Write-data generation

---

### `scoreboard_apb.sv`

APB transaction scoreboard.

Captures observed APB transactions and compares them against the expected transaction sequence.

The scoreboard is used to detect errors in:

- Address decoding
- Peripheral selection
- Read/write operation
- Transaction ordering
- Read-data behavior

---

### `uart_bfm.sv`

UART Bus Functional Model.

Provides UART stimulus and monitoring functionality.

It is used to verify:

- Serial transmission
- Serial reception
- Frame timing
- Data correctness

---

### `spi_bfm.sv`

SPI Bus Functional Model.

Monitors and verifies SPI communication.

It checks:

- Serial clock behavior
- Chip-select behavior
- MOSI data
- MISO data
- Transfer sequencing

---

### `cpu_monitor.sv`

CPU execution and pipeline monitor.

Observes processor activity during simulation, including:

- Instruction execution
- Program Counter movement
- Memory accesses
- Pipeline stalls
- Pipeline flushes
- Branch activity
- Execution statistics

---

### `coverage_model.sv`

Functional coverage model.

Tracks whether important functional scenarios have been exercised during verification.

Coverage includes areas such as:

- APB accesses
- Peripheral activity
- CPU operations
- Pipeline hazards
- Interrupt activity
- Negative and error scenarios

---

### `memory_model.sv`

Parameterized byte-addressable memory model.

Supports:

- Byte accesses
- Half-word accesses
- Word accesses
- Signed reads
- Unsigned reads

The model is used for memory-related verification and simulation support.

---

### `boot_rom.hex`

Boot ROM initialization file used by the verification environment.

The CPU begins execution using the program instructions stored in this file.

---

### `Makefile`

Automates compilation and execution of the verification environment.

It provides a convenient way to build and run simulations without manually entering every compiler command.

---

### `regression.sh`

Regression automation script.

Used to run multiple verification tests and collect regression results.

---

# Verification Strategy

The integrated verification flow follows this approach:

```text
Boot ROM / Firmware
        |
        v
   Processor Execution
        |
        v
 Address Decoder
        |
        v
 APB Interconnect
        |
        +--------+--------+--------+--------+
        |        |        |        |        |
        v        v        v        v        v
      GPIO     UART      SPI     Timer    PLIC
        |
        v
 Verification Environment
        |
        +-----------------------+
        | Scoreboard            |
        | Protocol BFMs         |
        | CPU Monitor           |
        | Functional Coverage   |
        +-----------------------+
