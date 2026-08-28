# Simulation Results

> Note: The folder name `Simultation` is retained to preserve the existing repository structure.

This folder contains selected simulation screenshots demonstrating the operation and verification of the major SoC subsystems.

The screenshots provide visual evidence of the processor, bus, peripheral, and full-system verification process.

---

## Contents

### `ARM Processor-5 stage pipeline with hazard and Execution Resolution.png`

Waveform demonstrating processor pipeline execution.

The simulation shows:

- Pipeline activity
- Instruction execution
- Hazard handling
- Stall behavior
- Execution resolution
- Control-flow behavior

---

### `APB Bus Transaction — Peripheral Write Verification.png`

Waveform demonstrating an APB peripheral write transaction.

The screenshot shows the APB protocol phases, including:

- Address setup
- Peripheral selection
- Enable phase
- Write control
- Write data

---

### `UART Transceiver Verification — Serial TX-RX Timing.png`

Waveform demonstrating UART transmission and reception.

The simulation is used to inspect:

- Serial frame timing
- TX operation
- RX operation
- Data transfer correctness

---

### `SPI Master Verification — Serial Transfer & Protocol Monitoring.png`

Waveform demonstrating SPI Master operation.

The screenshot shows:

- Serial clock generation
- Chip-select behavior
- MOSI transmission
- MISO reception
- Transfer timing

---

### `Full SoC Simulation — CPU Execution, APB Transactions & Functional Coverage.png`

Integrated full-system simulation.

This screenshot demonstrates interaction between:

- Processor execution
- Memory accesses
- APB transactions
- Peripheral activity
- Verification environment
- Functional coverage

---

## Purpose of this Folder

These screenshots provide visual verification evidence for the major functional blocks of the project.

They demonstrate:

- Processor functionality
- Pipeline hazard handling
- APB protocol operation
- UART communication
- SPI communication
- Full SoC integration

For the underlying waveform databases, see the [`VCD Files`](../VCD%20Files) directory.
