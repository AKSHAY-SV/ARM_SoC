# RTL Source Files

This folder contains the complete Verilog RTL implementation of the processor, memory system, address decoding, bus interconnect, peripherals, interrupt logic, and top-level SoC integration.

The RTL modules are organized to create a modular System-on-Chip architecture in which the processor communicates with memories and peripherals through the address-decoding and APB interconnect infrastructure.

---

## Folder Overview

The RTL implementation can be broadly divided into the following sections:

- Processor datapath and control
- Instruction and data memory
- Address decoding and bus infrastructure
- APB interconnect
- GPIO, UART, SPI, and Timer peripherals
- Interrupt controller
- Top-level SoC integration
- Supporting ARM/Thumb processor modules

---

# 1. Top-Level SoC Integration

### `soc_top.v`

The main top-level module of the SoC.

It integrates:

- Processor datapath
- Instruction memory
- Data memory
- Boot ROM
- RAM
- Address decoder
- APB subsystem
- GPIO peripheral
- UART
- SPI Master
- Timer
- PLIC-style interrupt controller

This module represents the complete integrated System-on-Chip and is used for full SoC simulation and verification.

---

### `top.v`

A smaller top-level processor integration module.

It is primarily used for processor-level simulation, debugging, and ISA regression before integrating the processor into the complete SoC.

---

### `reset_sync.v`

Implements reset synchronization logic.

The module ensures that the reset signal is safely synchronized with the clock domain before being used by sequential logic in the design.

---

### `ICG.v`

Integrated Clock Gating module.

This module provides clock-gating functionality that can be used to control clock propagation and reduce unnecessary switching activity.

---

# 2. Processor Datapath and Control

### `Data_Path.v`

The main processor datapath used in the integrated SoC.

It coordinates the major stages of processor execution, including:

- Instruction fetch
- Instruction decode
- Register read
- Immediate generation
- ALU execution
- Memory access
- Write-back

The datapath also supports pipeline control mechanisms such as stalls, forwarding, hazard handling, and control-flow flushing.

---

### `pc.v`

Implements the Program Counter logic.

The module stores and updates the address of the instruction currently being fetched and supports sequential execution and control-flow changes.

---

### `control_unit.v`

The main instruction control and decoding module.

It decodes instructions and generates the control signals required by the processor datapath, including signals for:

- ALU operation
- Register write
- Memory read
- Memory write
- Branching
- Jump operations
- Write-back selection

---

### `imm_gen.v`

Immediate Generator.

This module extracts and sign-extends immediate values from instruction fields based on the instruction format.

---

### `reg_file.v`

General-purpose register file.

It provides register storage and supports register read and write operations required by the processor datapath.

---

### `alu.v`

Arithmetic Logic Unit.

The ALU performs arithmetic and logical operations required during instruction execution.

Typical operations include:

- Addition
- Subtraction
- Logical AND
- Logical OR
- Logical XOR
- Shift operations
- Comparison operations

---

### `mac_unit.v`

Multiply-Accumulate unit.

This module performs multiplication followed by accumulation and provides dedicated hardware support for MAC operations.

---

### `multiplier.v`

Dedicated multiplication unit.

It performs multiplication operations used by the processor execution stage.

---

### `branch_unit.v`

Branch and control-flow resolution logic.

The module evaluates branch conditions and helps determine whether the Program Counter should continue sequentially or jump to a new target address.

---

### `barrel_shifter.v`

Barrel Shifter module.

Provides efficient logical and arithmetic shift operations used by the processor datapath and ARM-style instruction processing.

---

# 3. ARM/Thumb Processor Development Modules

The repository also contains modules developed for the ARM/Thumb processor architecture path.

These modules represent processor functionality associated with an ARMv6-M/Cortex-M0-style architecture.

---

### `arm_processor.v`

ARM processor microarchitecture module.

Contains the processor-level logic and supporting datapath/control functionality for the ARM-oriented implementation.

---

### `thumb_decoder.v`

Thumb instruction decoder.

Decodes 16-bit Thumb instructions and generates the required internal control signals.

---

### `execute_stage.v`

Execution-stage logic for the ARM/Thumb processor architecture.

Handles instruction execution, ALU operations, operand processing, and execution-related control operations.

---

### `writeback_stage.v`

Write-back stage logic.

Handles the final result selection and writes the appropriate execution or memory result back to the processor register file.

---

### `apsr.v`

Application Program Status Register.

Maintains processor condition flags used for conditional execution and arithmetic results.

Typical status flags include:

- Negative
- Zero
- Carry
- Overflow

---

### `cpu_constants.vh`

Shared processor definitions and constants.

This header file contains common parameters, opcode definitions, ALU operation codes, and other macros used across processor RTL modules.

---

# 4. Instruction and Data Memory

### `inst_mem.v`

Instruction memory implementation.

Stores the program instructions fetched and executed by the processor.

---

### `data_mem.v`

Data memory implementation.

Provides storage for processor load and store operations.

---

### `rom.v`

Read-Only Memory module.

Used for boot or program storage where data is initialized before execution and accessed by the processor.

---

### `ram.v`

Random Access Memory module.

Provides read/write storage for program data and runtime memory operations.

---

### `memory_interface.v`

Memory interface logic.

Acts as an interface between the processor and the memory subsystem, coordinating memory access operations.

---

### `boot_rom.hex`

Boot ROM initialization file.

Contains the hexadecimal program image loaded into the boot ROM during simulation.

---

### `firmware.hex`

Firmware/program image used during RTL simulation.

The processor fetches and executes the instructions stored in this file during simulation.

---

# 5. Address Decoding and Bus Infrastructure

### `address_decoder.v`

Address decoder.

Decodes processor memory addresses and determines which memory or peripheral region should respond to a transaction.

---

### `axi_decoder.v`

High-level address decoder.

Separates accesses between major SoC address regions such as:

- ROM
- RAM
- APB peripheral space

This module forms an important part of the memory-mapped SoC architecture.

---

### `bus_controller.v`

Bus-control logic.

Coordinates processor transactions and assists in routing memory and peripheral accesses through the appropriate interface.

---

### `ahb_master.v`

AMBA AHB/AHB-Lite master-side interface logic.

This module is part of the ARM-oriented bus architecture development and provides master-side transaction functionality.

---

# 6. APB Subsystem and Interconnect

### `apb_subsystem.v`

APB subsystem wrapper.

Connects the processor-side bus interface to the APB peripheral subsystem.

It manages the conversion and routing of peripheral transactions toward the APB interconnect.

---

### `apb_interconnect.v`

Central APB interconnect and address decoder.

Routes APB transactions to the appropriate peripheral based on the transaction address.

The interconnect connects the processor subsystem to:

- GPIO
- UART
- SPI
- Timer
- Interrupt controller

---

# 7. GPIO Peripheral

### `gpio_apb.v`

APB-connected GPIO peripheral.

The module provides programmable GPIO functionality through memory-mapped registers.

It supports:

- GPIO data register
- Direction control
- Input monitoring
- Output control

The GPIO interface is implemented using separate input, output, and output-enable signals, making it suitable for ASIC implementation and pad-level integration.

---

# 8. Timer Peripheral

### `timer_apb.v`

APB-controlled timer peripheral.

The timer includes functionality such as:

- Configurable counting
- Down-counter operation
- Auto-reload
- Status monitoring
- Interrupt generation

The timer interrupt can be routed to the interrupt controller and processor.

---

# 9. SPI Peripheral

### `spi_master_apb.v`

APB-controlled SPI Master.

Provides memory-mapped control of SPI communication.

The module manages:

- Serial clock generation
- Chip-select control
- MOSI transmission
- MISO reception
- Transfer completion
- Interrupt generation

---

# 10. Interrupt Controller

### `plic_simple.v`

Simplified PLIC-style interrupt controller.

Collects interrupt requests generated by multiple peripherals and combines them into a processor-visible interrupt request.

Interrupt sources include:

- Timer
- SPI
- GPIO
- UART

The module supports interrupt pending and clearing behavior.

---

# 11. UART Peripheral

The UART implementation is divided into multiple modular blocks.

### `apb_uart_wrapper.v`

Connects the UART subsystem to the APB bus.

---

### `apb_uart.v`

Handles APB transactions associated with UART registers and control signals.

---

### `uart_regs.v`

UART register block.

Stores UART configuration, control, status, and data registers.

---

### `uart_top.v`

Top-level UART core integrating the transmitter, receiver, and supporting logic.

---

### `baud_gen.v`

Baud-rate generator.

Generates the timing required for UART serial transmission and reception.

---

### `uart_tx.v`

UART transmitter.

Converts parallel transmit data into a serial UART frame.

---

### `uart_rx.v`

UART receiver.

Samples incoming serial data and reconstructs the transmitted parallel data.

---

### `uart_final.v`

Final UART integration module used in the SoC implementation.

Combines the UART functionality into the interface used by the integrated SoC and APB subsystem.

---

# RTL Architecture Flow

The major data flow through the SoC can be summarized as:

```text
                    +------------------+
                    |    Processor     |
                    |    Data_Path     |
                    +---------+--------+
                              |
                              v
                    +------------------+
                    | Address Decoder  |
                    +----+--------+----+
                         |        |
              +----------+        +----------+
              |                              |
              v                              v
        +-----------+                 +-------------+
        | ROM / RAM |                 | APB Subsystem|
        +-----------+                 +------+------+
                                             |
                                             v
                                   +------------------+
                                   | APB Interconnect |
                                   +--+---+---+---+---+
                                      |   |   |   |   |
                                      v   v   v   v   v
                                    GPIO UART SPI TIMER PLIC
