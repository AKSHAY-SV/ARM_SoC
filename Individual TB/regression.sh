#!/usr/bin/env bash
# ============================================================================
# regression.sh - SoC verification regression runner.
#
#  1. Regenerates the firmware image (boot_rom.hex) from the assembler
#  2. Compiles RTL + testbench with Icarus Verilog
#  3. Runs the simulation (from Complete_TB so boot_rom.hex resolves)
#  4. Prints the coverage + scoreboard summaries
#
# Exit status reflects a compile/simulation failure, not (yet) the pass/fail
# verdict of the checks themselves (the simulation prints PASS/FAIL lines).
# ============================================================================
set -euo pipefail
cd "$(dirname "$0")"

echo "=== [1/3] Generating firmware (boot_rom.hex) ==="
python3 tools/asm_rv32i.py

echo "=== [2/3] Compiling with Icarus Verilog ==="
make compile

echo "=== [3/3] Running simulation ==="
make sim

echo ""
echo "=== Regression run complete. See ../Complete_Simulation/ for waveforms and report. ==="
