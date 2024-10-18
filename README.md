# PNR-CoreV1
RV32I Pipelined Core
The core have 5 pipeline stages, Influenced by "Computer Organization and Design RISC-V Edition".
The Core supports:
1- Forwarding Unit
2- Load Data Hazard Detection
3- Assume Branch Not Taken
4- Load-Store Forwarding For memory copy operations

TODO:
1- More Fancy Branch Prediction
2- Moving Branch Jump Unit to ID Stage To Reduce wasting cycle from 2 to 1 per wrong prediction
3- Verifiying the core using the riscv-arch-test
4- Adding Cache memory
