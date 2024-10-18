# PNR-CoreV1

## RV32I Pipelined Core

The core has 5 pipeline stages, influenced by "Computer Organization and Design RISC-V Edition".

### Features
The Core supports:
1. Forwarding Unit
2. Load Data Hazard Detection
3. Assume Branch Not Taken
4. Load-Store Forwarding for memory copy operations

### TODO
1. Implement a more advanced branch prediction
2. Move Branch Jump Unit to ID Stage to reduce wasted cycles from 2 to 1 per wrong prediction
3. Verify the core using the `riscv-arch-test`
4. Add cache memory

