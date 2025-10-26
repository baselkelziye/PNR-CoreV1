# ---- Tool & config ----
VERILATOR        ?= verilator
CORE_VERBOSITY   ?= 500
TOP_MODULE       ?= core

# Define source directory variable
SRC_DIR          := ../../src

# Use the variable throughout the Makefile
SRCS := $(shell find $(SRC_DIR) -name '*.v')

# C++ mains
BASIC_MAIN  ?= sim/main.cpp
RISCOF_MAIN ?= sim/main.cpp

# Separate obj dirs
OBJDIR_BASIC  := obj_basic
OBJDIR_RISCOF := artifacts

BIN_RISCOF    := $(OBJDIR_RISCOF)/V$(TOP_MODULE)
BIN_BASIC := $(OBJDIR_BASIC)/V$(TOP_MODULE)

# Common Verilator flags (using SRC_DIR variable)
VERILATOR_FLAGS := --cc --exe -j 4 --timescale 1ns/1ps -I$(SRC_DIR) \
                   --Wno-fatal --quiet-stats  -DCORE_VERBOSITY=$(CORE_VERBOSITY)

TRACE_SWITCH  := $(if $(filter 1,$(trace)),--trace,)
CFLAGS_EXTRA  := $(if $(filter 1,$(trace)),-DTRACE,)

.PHONY: all build-basic build-riscof run riscof clean

all: build-riscof

build-riscof: $(BIN_RISCOF)
$(BIN_RISCOF): $(SRCS) $(RISCOF_MAIN)
	$(VERILATOR) $(VERILATOR_FLAGS) $(TRACE_SWITCH) -Mdir $(OBJDIR_RISCOF) \
    --top-module $(TOP_MODULE) $(SRCS) $(abspath $(RISCOF_MAIN)) \
    -CFLAGS "-I$(SRC_DIR) $(CFLAGS_EXTRA)"
	$(MAKE) -C $(OBJDIR_RISCOF) -j -f V$(TOP_MODULE).mk V$(TOP_MODULE)

riscof: build-riscof
	stdbuf -o0 ./$(BIN_RISCOF) $(if $(filter 1,$(dump)),--dump,) $(if $(filter 1,$(trace)),--trace,)

# ---- Clean ----
clean:
	rm -rf $(OBJDIR_BASIC) $(OBJDIR_RISCOF) core.vcd memory_dump.txt register_dump.txt DUT.signature