# GDSII Layout

This folder contains visualizations of the final GDSII physical layout generated for the ARM SoC.

GDSII is the industry-standard layout format used to represent the physical geometry of an integrated circuit before fabrication.

The final GDSII layout is generated after completing the major ASIC implementation stages, including synthesis, floorplanning, placement, clock-tree synthesis, routing, timing analysis, and physical verification.

---

## Contents

### `arm gdsii.png`

Primary full-chip view of the generated ARM SoC GDSII layout.

This image provides an overall view of the final physical geometry of the implemented design.

---

### `gdsii without fill.png`

GDSII layout view with fill structures removed or hidden.

Removing fill structures improves the visibility of the functional routing and standard-cell geometry.

---

### `no text no fill gdsii.png`

Simplified GDSII layout view with text labels and fill structures removed.

This provides a cleaner visualization of the physical routing and placement geometry.

---

### `zoomed in GDSII.png`

Magnified view of the final GDSII layout.

This image provides a closer look at:

- Standard-cell placement
- Routing tracks
- Metal interconnects
- Via structures
- Physical layout geometry

---

### `Screenshot 2026-08-28 114538.png`

Additional screenshot captured during GDSII layout inspection.

This image provides another view of the completed physical design.

---

## RTL-to-GDSII Flow

The final GDSII is generated through the following flow:

```text
Verilog RTL
     |
     v
RTL Synthesis
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
Global and Detailed Routing
     |
     v
Static Timing Analysis
     |
     v
DRC / LVS / Antenna Checks
     |
     v
GDSII Stream-Out
