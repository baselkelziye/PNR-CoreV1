#!/bin/bash

set -e  # Exit on any error

echo "Step 1: Assembling with rv32imzicsr..."
riscv32-unknown-elf-as -march=rv32imzicsr -mabi=ilp32 -o load_misaligned_exception.o load_misaligned_exception.s

echo "Step 2: Linking..."
riscv32-unknown-elf-ld -T link.ld -o load_misaligned_exception.elf load_misaligned_exception.o

echo "Step 3: Generating disassembly..."
riscv32-unknown-elf-objdump -d -M no-aliases load_misaligned_exception.elf > load_misaligned_exception.dis

echo "Step 4: Extracting binary sections..."
riscv32-unknown-elf-objcopy -O binary --only-section=.text load_misaligned_exception.elf text_section.bin
riscv32-unknown-elf-objcopy -O binary --only-section=.text.trap load_misaligned_exception.elf trap_section.bin

echo "Step 5: Converting to readmemh format..."
hexdump -v -e '1/4 "%08x\n"' text_section.bin > memory_0.hex
hexdump -v -e '1/4 "%08x\n"' trap_section.bin > memory_2000.hex

echo "Step 6: Verification"
echo "Instructions at 0x00000000: $(wc -l < memory_0.hex)"
echo "Instructions at 0x00002000: $(wc -l < memory_2000.hex)"

echo "Done! Files created:"
echo "  memory_0.hex    - Instructions for address 0x00000000"
echo "  memory_2000.hex - Instructions for address 0x00002000"
echo "  load_misaligned_exception.dis - Disassembly for verification"