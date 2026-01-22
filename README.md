# PNR-CoreV1
This core was designed as a project in Processor Architecure lecture taught at UPC under Prof. Roger Espasa.

## RV32IM Pipelined Core

### Features
The Core currently supports:
1. 6 Stage Pipeline
2. Directed Mapped Parametrizable Instruction and Data Caches
3. Common Memory
4. Multi level Virtual Memory Support
5. itlb and dtlb (Custom itlb write, dtlb write instructions to update tlbs)
6. Software Page Walking
7. Unified Trap Handler Code
8. Supervisor mode (With Minimum CSR support for Virtual Memory Support)
9. Store Buffer
10. Registar Aliases Table (Used for ROB forwarding)
11. Reorder buffer
12. 2 bit bimodal Branch Predictor

### Verification
1. RISCOF framework integrated to support riscv-arch-suite
2. cocotb based testbenches for basic tests


#### Virtual Memory
The virtual memory support is very basic, The core doesn't have a MMU, hence pagewalking and itlb updates are done by the OS code with the new priviledged `itlb write` and `dtlb write` insturctions.

The Virtual to Physicall Address mapping is done like: `PA = VA + 0x41000` it can be observed from the image below why `0x41000` was chosen.

Page Tables reserved addresses from `0x5000 - 0x405FFF` which is roughly equal to 4MB.

SATP Register is initalized to point to L1 Page table (0x5000)

![alt text](images/PA-Adress%20Spaces.drawio.png)

#### itlb and dtlb Write instructions

This 2 instructions takes 2 operands, one operand has the virtual address and the other one has the mapping.

> **_NOTE:_**  since the Virtual address is already present in CSR STVAL this instruction can be modified to use implicit register for virtual address and explicit register that contains the mapping!.

![alt text](images/tlb_writes.png)