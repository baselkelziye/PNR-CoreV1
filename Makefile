# ---- Tool & config ----
VERILATOR      ?= verilator
CORE_VERBOSITY ?= 600
TOP_MODULE     ?= core

# Define source directory variable
SRC_DIR        := src

# Collect Verilog sources
SRCS := $(shell find $(SRC_DIR) -name '*.v')

# C++ main
MAIN ?= sim/main.cpp

# Object directory
OBJDIR := obj

# Binary output
BIN := $(OBJDIR)/V$(TOP_MODULE)

# Common Verilator flags 
VERILATOR_FLAGS := --cc --exe -j 4 --timescale 1ns/1ps -I$(SRC_DIR) \
                   --Wno-fatal  --public -DCORE_VERBOSITY=$(CORE_VERBOSITY)

TRACE_SWITCH  := $(if $(filter 1,$(trace)),--trace,)
CFLAGS_EXTRA  := $(if $(filter 1,$(trace)),-DTRACE,)
MEM_DUMP      := $(if $(filter 1,$(mem_dump)), -DMEM_DUMP)

.PHONY: all build run clean

all: build

build: $(BIN)

$(BIN): $(SRCS) $(MAIN)
	$(VERILATOR) $(VERILATOR_FLAGS) $(TRACE_SWITCH) -Mdir $(OBJDIR) \
		--top-module $(TOP_MODULE) $(SRCS) $(abspath $(MAIN)) \
		-CFLAGS  -DVL_DEBUG"-I$(SRC_DIR) $(CFLAGS_EXTRA)" $(MEM_DUMP)
	$(MAKE) -C $(OBJDIR) -j -f V$(TOP_MODULE).mk V$(TOP_MODULE)

run: build
	./$(BIN)

# ---- Clean ----
clean:
	rm -rf $(OBJDIR) core.vcd memory_dump.txt register_dump.txt DUT.signature trace_core.log memory_dump.log
