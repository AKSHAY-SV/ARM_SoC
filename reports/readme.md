
---

# 8. `reports/readme.md`

```md
# Reports

This folder contains simulation, verification, synthesis, timing, physical-design, and signoff reports generated throughout the ARM SoC implementation flow.

The reports document the complete progression from RTL functionality to physical ASIC implementation.

---

# Verification and Simulation Reports

### `verification_report.md`

Main functional-verification summary.

Includes information related to:

- CPU-driven firmware testing
- APB verification
- Peripheral verification
- ISA regression
- Pipeline monitoring
- Functional coverage

---

### `final_verification_summary.txt`

Consolidated summary of the final verification and implementation results.

---

### `rtl_simulation.txt`

Summary of RTL simulation results.

---

### `rtl_verification.txt`

RTL verification report describing the functional checks performed on the design.

---

### `functional_coverage.txt`

Functional coverage results.

This report indicates whether the planned verification scenarios were exercised.

---

### `firmware+verilog compilation+Simulation.txt`

Build and simulation transcript showing:

- Firmware preparation
- Verilog/SystemVerilog compilation
- Simulation execution
- Verification output

---

# Synthesis and Physical Design Reports

### `synthesis.txt`

RTL synthesis report.

Contains information related to:

- RTL elaboration
- Logic optimization
- Cell statistics
- Synthesized netlist
- Synthesis warnings

---

### `floorplan.txt`

Floorplanning report.

Contains information related to the initial physical setup of the ASIC.

---

### `placement.txt`

Standard-cell placement report.

Contains placement results and placement-related checks.

---

### `cts.txt`

Clock Tree Synthesis report.

Contains information about clock distribution and CTS results.

---

### `routing.txt`

Routing report.

Contains information about global and detailed routing.

---

### `physical_design.txt`

Detailed physical-design flow report.

---

### `physical_design_summary.txt`

Consolidated summary of:

- Floorplanning
- Placement
- CTS
- Routing
- Timing
- Physical checks

---

### `power_grid.txt`

Power-distribution network information.

---

### `ir_drop.txt`

IR-drop analysis results.

---

### `thermal.txt`

Thermal-analysis information.

---

# Timing Reports

### `constraints.txt`

Timing and implementation constraints used during the ASIC flow.

---

### `timing.txt`

Complete static-timing analysis summary.

---

### `setup_timing.txt`

Setup-timing analysis results.

---

### `hold_timing.txt`

Hold-timing analysis results.

---

### `critical_paths.txt`

Critical-path analysis.

Identifies timing-critical logic paths in the implemented design.

---

# Physical Verification and Signoff

### `drc.txt`

Design Rule Check results.

DRC verifies that the physical layout follows the technology design rules.

---

### `lvs.txt`

Layout-versus-Schematic verification results.

LVS checks whether the physical layout connectivity matches the intended circuit/netlist.

---

### `antenna.txt`

Antenna-rule analysis.

Checks for routing structures that may create antenna effects during fabrication.

---

### `gdsii.txt`

GDSII generation and layout stream-out information.

---

# Recommended Reading Order

For a complete understanding of the implementation results:

1. `verification_report.md`
2. `rtl_simulation.txt`
3. `functional_coverage.txt`
4. `synthesis.txt`
5. `floorplan.txt`
6. `placement.txt`
7. `cts.txt`
8. `routing.txt`
9. `timing.txt`
10. `setup_timing.txt`
11. `hold_timing.txt`
12. `drc.txt`
13. `lvs.txt`
14. `antenna.txt`
15. `gdsii.txt`

---

## Purpose of this Folder

This folder provides the supporting evidence for the complete RTL-to-GDSII implementation flow.

It documents:

```text
RTL
 |
 v
Functional Verification
 |
 v
Synthesis
 |
 v
Floorplanning
 |
 v
Placement
 |
 v
Clock Tree Synthesis
 |
 v
Routing
 |
 v
Timing Analysis
 |
 v
Physical Verification
 |
 v
GDSII Generation
