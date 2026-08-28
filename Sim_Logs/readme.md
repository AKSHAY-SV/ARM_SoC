
---

# 5. `Sim_Logs/readme.md`

```md
# Simulation Logs

This folder contains textual logs generated during RTL simulation of individual modules and integrated SoC configurations.

The logs provide a record of compilation, simulation execution, verification checks, and PASS/FAIL results.

---

## Contents

### `apb_interconnect.log`

Simulation log for the APB address-decoding and peripheral-routing logic.

---

### `apb_subsystem.log`

Simulation log for the integrated APB subsystem.

---

### `axi_decoder.log`

Simulation log for the address decoder responsible for routing transactions between major memory and peripheral regions.

---

### `gpio_apb.log`

Simulation log for the APB GPIO peripheral.

---

### `plic_simple.log`

Simulation log for the PLIC-style interrupt controller.

---

### `ram.log`

Simulation log for RAM read and write behavior.

---

### `rom.log`

Simulation log for ROM and boot-memory behavior.

---

### `soc_top.log`

Simulation log for the complete integrated `soc_top` design.

---

### `spi_master_apb.log`

Simulation log for the APB-controlled SPI Master.

---

### `timer_apb.log`

Simulation log for the APB timer peripheral.

---

### `top.log`

Simulation log for the processor-level top module.

---

### `top_isa_regression.log`

ISA-oriented processor regression log.

This log records the execution of processor instruction and datapath tests.

---

### `uart_final.log`

Simulation log for the final UART integration.

---

## Purpose of this Folder

The simulation logs are useful for:

- Reviewing PASS/FAIL status
- Debugging simulation failures
- Checking compiler output
- Tracking regression results
- Verifying module-level functionality

The corresponding waveform files are available in the [`VCD Files`](../VCD%20Files) directory.
