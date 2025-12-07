#!/bin/bash

set -e  # Exit on any error

echo "Step 1: Assembling with rv32imzicsr..."
riscv32-unknown-elf-as -march=rv32imzicsr -mabi=ilp32 -o trap_handler.o ../cocotb/assembly_codes/trap_handler.s

echo "Step 2: Linking..."
riscv32-unknown-elf-ld -T link.ld -o trap_handler.elf trap_handler.o

echo "Step 3: Generating disassembly..."
riscv32-unknown-elf-objdump -d -M no-aliases trap_handler.elf > trap_handler.dis

echo "Step 4: Extracting binary sections..."
riscv32-unknown-elf-objcopy -O binary --only-section=.text trap_handler.elf text_section.bin

echo "Step 5: Converting to readmemh format..."
hexdump -v -e '1/4 "%08x\n"' text_section.bin > trap_handler.hex


echo "Step 6: Verification"
echo "Instructions at 0x00000000: $(wc -l < trap_handler.hex)"

echo "Done! Files created:"
echo "  trap_handler.dis - Disassembly for verification"