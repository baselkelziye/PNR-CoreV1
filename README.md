# PNR-CoreV1

## RV32I Pipelined Core

The core implements a 5-stage pipeline, inspired by "Computer Organization and Design RISC-V Edition."

### Features
The Core currently supports:
1. Forwarding Unit
2. Load Data Hazard Detection
3. 2-Bit Bimodal Branch Predictor
4. Load-Store Forwarding for memory copy operations

### TODO
- ✅ **Implement a more advanced branch prediction**
- Move Branch Jump Unit to the ID Stage to reduce misprediction penalty from 2 to 1 cycle
- Verify core functionality using the `riscv-arch-test` suite
- Integrate cache memory

### Summary
The core is now partially optimized with essential hazard detection and basic branch prediction, with further plans to improve prediction accuracy, decrease misprediction penalties, and add cache support.
