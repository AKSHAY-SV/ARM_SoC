
---

# 2. `Floorplan Components/readme.md`

```md
# Floorplan Components

This folder contains detailed physical-layout views of individual routing, power, and via layers generated during the ASIC physical-design flow.

These images provide a closer inspection of the physical implementation beyond the overall floorplan.

---

## Contents

### `VGND.png`

View highlighting the ground power-distribution network.

The `VGND` structures provide the ground connection used by the standard cells and other physical components of the design.

---

### `VPWR.png`

View highlighting the power-distribution network.

The `VPWR` structures distribute the power supply across the core and provide the required power connections to the placed standard cells.

---

### `met1.png`

Physical layout view of the Metal 1 routing layer.

Metal 1 is generally used for local routing and connections between nearby standard cells.

---

### `met2.png`

Physical layout view of the Metal 2 routing layer.

This layer provides additional routing resources and is used to reduce routing congestion.

---

### `met3.png`

Physical layout view of the Metal 3 routing layer.

Metal 3 is typically used for longer interconnections and additional routing capacity.

---

### `met4.png`

Physical layout view of the Metal 4 routing layer.

This layer provides higher-level routing resources for signals and physical interconnections.

---

### `met5.png`

Physical layout view of the Metal 5 routing layer.

Higher metal layers are generally useful for longer-distance routing and large-scale power or signal distribution.

---

### `via.png`

View of via structures used to electrically connect routing layers.

Vias provide vertical connectivity between adjacent metal layers.

---

### `via2.png`

View of additional via structures between routing layers.

These vias provide inter-layer electrical connections at higher routing levels.

---

### `via3.png`

View of higher-level via structures.

They provide vertical connectivity between additional metal layers used in the physical design.

---

### `via4.png`

View of upper-level via structures used for routing-layer connectivity.

---

### `timing1.png`

Timing-related physical-design screenshot.

This image provides visual information associated with timing analysis during the ASIC implementation flow.

---

## Purpose of this Folder

This folder documents the physical structures used to implement the SoC.

The images can be used to inspect:

- Power distribution
- Ground distribution
- Multi-layer routing
- Via connectivity
- Metal-layer utilization
- Physical implementation details

Together, these views demonstrate how the logical RTL design is translated into an interconnected multi-layer ASIC layout.
