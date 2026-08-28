# ============================================================================
# Makefile for the Complete_TB SoC verification environment (Icarus Verilog)
#
# Targets:
#   all      - full flow: firmware -> compile -> simulate
#   hex      - regenerate boot_rom.hex from tools/asm_rv32i.py
#   compile  - compile RTL + TB into ../Complete_Simulation/soc_tb.vvp
#   sim      - run the compiled simulation (from Complete_TB so the
#              $readmemh("boot_rom.hex") relative path resolves)
#   clean    - remove generated artifacts
#
# Run `make` from inside Complete_TB (the Makefile's directory).
# ============================================================================

IVERILOG ?= iverilog
VVP      ?= vvp
PYTHON   ?= python3

RTL_DIR := ../ARM_SoC/rtl
OUT_DIR := ../Complete_Simulation

RTL_SRCS := \
    $(RTL_DIR)/soc_top.v \
    $(RTL_DIR)/reset_sync.v \
    $(RTL_DIR)/Data_Path.v \
    $(RTL_DIR)/pc.v \
    $(RTL_DIR)/control_unit.v \
    $(RTL_DIR)/imm_gen.v \
    $(RTL_DIR)/reg_file.v \
    $(RTL_DIR)/alu.v \
    $(RTL_DIR)/mac_unit.v \
    $(RTL_DIR)/inst_mem.v \
    $(RTL_DIR)/data_mem.v \
    $(RTL_DIR)/apb_subsystem.v \
    $(RTL_DIR)/apb_interconnect.v \
    $(RTL_DIR)/gpio_apb.v \
    $(RTL_DIR)/timer_apb.v \
    $(RTL_DIR)/spi_master_apb.v \
    $(RTL_DIR)/plic_simple.v \
    $(RTL_DIR)/apb_uart_wrapper.v \
    $(RTL_DIR)/uart_final.v \
    $(RTL_DIR)/apb_uart.v \
    $(RTL_DIR)/uart_regs.v \
    $(RTL_DIR)/uart_top.v \
    $(RTL_DIR)/baud_gen.v \
    $(RTL_DIR)/uart_tx.v \
    $(RTL_DIR)/uart_rx.v

TB_SRCS := \
    soc_tb.sv \
    uart_bfm.sv \
    spi_bfm.sv \
    coverage_model.sv \
    cpu_monitor.sv \
    scoreboard_apb.sv

VVP_FILE := $(OUT_DIR)/soc_tb.vvp

.PHONY: all hex compile sim clean

all: sim

hex:
	$(PYTHON) tools/asm_rv32i.py

compile: hex
	$(IVERILOG) -g2012 -o $(VVP_FILE) -I $(RTL_DIR) $(TB_SRCS) $(RTL_SRCS)

sim: compile
	$(VVP) $(VVP_FILE)

clean:
	rm -f $(VVP_FILE) $(OUT_DIR)/soc_tb.vcd $(OUT_DIR)/verification_report.txt
