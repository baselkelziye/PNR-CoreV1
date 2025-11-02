SIM=verilator
WAVES=1
TOPLEVEL_LANG=verilog

HDL_DIR := ../../src
PERIPHERAL_DIR := ../../src/peripheral
VERILOG_SOURCES := $(wildcard $(HDL_DIR)/*.v)
VERILOG_SOURCES += $(wildcard $(PERIPHERAL_DIR)/*.v)
TOPLEVEL = core
MODULE = general_tests

# Hard code core_verbosity - use +define+ for Verilog
CORE_VERBOSITY=0

VERILATOR_FLAGS := --timescale 1ns/1ps -I$(HDL_DIR) \
                   --Wno-fatal --public -DCORE_VERBOSITY=$(CORE_VERBOSITY) \
                   -fno-dedup -Wno-WIDTH 

# Base compile args
COMPILE_ARGS := -I$(HDL_DIR)

# Add Verilator-specific flags when using verilator
ifeq ($(SIM),verilator)
    COMPILE_ARGS += $(VERILATOR_FLAGS)
endif

ifeq ($(WAVES), 1)
    COMPILE_ARGS += -DCOCOTB_SIM=1
endif

include $(shell cocotb-config --makefiles)/Makefile.sim