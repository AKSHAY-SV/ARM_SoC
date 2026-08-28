# Floorplan

This folder contains the main physical floorplan views of the ARM SoC generated during the ASIC physical-design flow.

The floorplan stage converts the synthesized RTL design into a physical implementation by defining the chip area, core area, placement region, and power-delivery structures.

---

## Contents

### `full floorplan.png`

Complete top-level floorplan of the SoC.

This image provides an overall view of the physical implementation, including:

- Die boundary
- Core boundary
- Placement region
- Power distribution structures
- Major routing regions
- Overall physical organization of the design

It provides a high-level view of how the logical RTL design is mapped into a physical ASIC layout.

---

### `placement included.png`

Floorplan view after standard-cell placement.

This image shows how the synthesized standard cells are distributed across the available core area.

The placement stage is responsible for determining the physical location of the standard cells while considering:

- Cell utilization
- Connectivity
- Timing
- Congestion
- Routing resources

This view demonstrates the transition from the logical netlist to a physically placed implementation.

---

## Physical Design Flow Context

The floorplan and placement stages occur after RTL synthesis and before final routing.

The overall ASIC flow is:

```text
RTL Design
    |
    v
Synthesis
    |
    v
Floorplanning
    |
    v
Power Grid Generation
    |
    v
Standard Cell Placement
    |
    v
Clock Tree Synthesis
    |
    v
Routing
    |
    v
Static Timing Analysis
    |
    v
DRC / LVS / Antenna Checks
    |
    v
GDSII Generation
