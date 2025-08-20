# ---- Tool & config ----
VERILATOR        ?= verilator
CORE_VERBOSITY   ?= 500
TOP_MODULE       ?= core

SRCS := $(shell find src -name '*.v')

# C++ mains
BASIC_MAIN  ?= sim/main.cpp
RISCOF_MAIN ?= tests/riscof_integration/sim/main.cpp

# Separate obj dirs
OBJDIR_BASIC  := obj_basic
OBJDIR_RISCOF := tests/riscof_integration/artifacts

BIN_RISCOF    := $(OBJDIR_RISCOF)/V$(TOP_MODULE)
BIN_BASIC := $(OBJDIR_BASIC)/V$(TOP_MODULE)

# Common Verilator flags
VERILATOR_FLAGS := --cc --exe -j 4 --timescale 1ns/1ps -Isrc \
                   --Wno-fatal -DCORE_VERBOSITY=$(CORE_VERBOSITY)

TRACE_SWITCH  := $(if $(filter 1,$(trace)),--trace,)
CFLAGS_EXTRA  := $(if $(filter 1,$(trace)),-DTRACE,)

.PHONY: all build-basic build-riscof run riscof clean

all: build-basic

# ---- Build targets ----
build-basic: $(BIN_BASIC)
$(BIN_BASIC): $(SRCS) $(BASIC_MAIN)
	$(VERILATOR) $(VERILATOR_FLAGS) $(TRACE_SWITCH) -Mdir $(OBJDIR_BASIC) \
		--top-module $(TOP_MODULE) $(SRCS) $(BASIC_MAIN) \
		-CFLAGS "-Isrc $(CFLAGS_EXTRA)"
	$(MAKE) -C $(OBJDIR_BASIC) -j -f V$(TOP_MODULE).mk V$(TOP_MODULE)

build-riscof: $(BIN_RISCOF)
$(BIN_RISCOF): $(SRCS) $(RISCOF_MAIN)
	$(VERILATOR) $(VERILATOR_FLAGS) $(TRACE_SWITCH) -Mdir $(OBJDIR_RISCOF) \
    --top-module $(TOP_MODULE) $(SRCS) $(abspath $(RISCOF_MAIN)) \
    -CFLAGS "-Isrc $(CFLAGS_EXTRA)"

	$(MAKE) -C $(OBJDIR_RISCOF) -j -f V$(TOP_MODULE).mk V$(TOP_MODULE)
# ---- Run targets ----
run: build-basic
	./$(BIN_BASIC)  $(if $(filter 1,$(dump)),--dump,)  $(if $(filter 1,$(trace)),--trace,)

riscof: build-riscof
	./$(BIN_RISCOF) $(if $(filter 1,$(dump)),--dump,) $(if $(filter 1,$(trace)),--trace,)

# ---- Clean ----
clean:
	rm -rf $(OBJDIR_BASIC) $(OBJDIR_RISCOF) core.vcd memory_dump.txt register_dump.txt DUT.signature
