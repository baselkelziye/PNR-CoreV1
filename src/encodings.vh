`ifndef encodings_vh
`define encodings_vh

// Opcode definitions
`define RTYPE_OPCODE     5'b01100
`define ITYPE_OPCODE     5'b00100
`define STORE_OPCODE     5'b01000
`define LOAD_OPCODE      5'b00000
`define BRANCH_OPCODE    5'b11000
`define JALR_OPCODE      5'b11001
`define JAL_OPCODE       5'b11011
`define AUIPC_OPCODE     5'b00101
`define LUI_OPCODE       5'b01101
`define TLB_OPCODE       5'b00010

// I-Type Funct3 definitions
`define ADDI_FUNCT3          3'b000
`define SLTI_FUNCT3          3'b010
`define SLTIU_FUNCT3         3'b011
`define XORI_FUNCT3          3'b100
`define ORI_FUNCT3           3'b110
`define ANDI_FUNCT3          3'b111
`define SLLI_FUNCT3          3'b001 
`define BMU_SHAMT_A_FUNCT3   3'b001
`define BMU_SHAMT_B_FUNCT3   3'b101
`define ITLB_FUNCT3          3'b000
`define DTLB_FUNCT3          3'b001

// JALR Funct3 definition
`define JALR_FUNCT3          3'b000

// Load Funct3 definitions
`define LB_FUNCT3            3'b000
`define LH_FUNCT3            3'b001
`define LW_FUNCT3            3'b010
`define LBU_FUNCT3           3'b100
`define LHU_FUNCT3           3'b101

// Store Funct3 definitions
`define SB_FUNCT3            3'b000
`define SH_FUNCT3            3'b001
`define SW_FUNCT3            3'b010

// Branch Funct3 definitions
`define BEQ_FUNCT3           3'b000
`define BNE_FUNCT3           3'b001
`define BLT_FUNCT3           3'b100
`define BGE_FUNCT3           3'b101
`define BLTU_FUNCT3          3'b110
`define BGEU_FUNCT3          3'b111

// I-Type Funct7 definitions
`define SLLI_FUNCT7          7'b0000000
`define SRLI_FUNCT7          7'b0000000
`define SRAI_FUNCT7          7'b0100000

// R-Type RV32I Funct7 definitions
`define ADD_FUNCT7           7'b0000000
`define SUB_FUNCT7           7'b0100000
`define SLL_FUNCT7           7'b0000000
`define SLT_FUNCT7           7'b0000000
`define SLTU_FUNCT7          7'b0000000
`define XOR_FUNCT7           7'b0000000
`define SRL_FUNCT7           7'b0000000
`define SRA_FUNCT7           7'b0100000
`define OR_FUNCT7            7'b0000000
`define AND_FUNCT7           7'b0000000

// Funct3 definitions for R-Type
`define ADD_FUNCT3           3'b000
`define SUB_FUNCT3           3'b000
`define SLL_FUNCT3           3'b001
`define SLT_FUNCT3           3'b010
`define SLTU_FUNCT3          3'b011
`define XOR_FUNCT3           3'b100
`define SRL_FUNCT3           3'b101
`define SRA_FUNCT3           3'b101
`define OR_FUNCT3            3'b110
`define AND_FUNCT3           3'b111



`define ADD_ALU_OP          4'b0000
`define SUB_ALU_OP          4'b0001
`define SLL_ALU_OP          4'b0010
`define SLT_ALU_OP          4'b0011
`define SLTU_ALU_OP         4'b0100
`define XOR_ALU_OP          4'b0101
`define SRL_ALU_OP          4'b0110
`define SRA_ALU_OP          4'b0111
`define OR_ALU_OP           4'b1000
`define AND_ALU_OP          4'b1001
`define LUI_ALU_OP          4'b1010
`define JALR_ALU_OP         4'b1011
`define ASSIGN_OP           4'b1100
`define CLEAR_OP            4'b1101
`define DEFAULT_ALU_OP      4'b1111

//Peripherals Memory Map
`define UART_CTRL   32'h20000000
`define UART_STATUS 32'h20000004
`define UART_RX     32'h20000008
`define UART_TX     32'h2000000C
//CSR
`define SYSTEM_OPCODE    5'b11100
`define ECALL  3'b000
`define EBREAK 3'b000
`define SRET   3'b000
`define CSRRW  3'b001
`define CSRRS  3'b010  
`define CSRRC  3'b011
`define CSRRWI 3'b101
`define CSRRSI 3'b110
`define CSRRCI 3'b111
`define M_MODE 2'b11
`define S_MODE 2'b01
`define U_MODE 2'b00

// Machine Information Registers (RO)
`define MVENDORID        12'hf11  // Vendor ID.
`define MARCHID          12'hf12  // Architecture ID.
`define MIMPID           12'hf13  // Implementation ID.
`define MHARTID          12'hf14  // Hardware thread ID.

// Machine Trap Setup (RW)
`define MSTATUS          12'h300  // Machine status register.
`define MISA             12'h301  // ISA and extensions
`define MEDELEG          12'h302  // Machine exception delegation register.
`define MIDELEG          12'h303  // Machine interrupt delegation register.
`define MIE              12'h304  // Machine interrupt-enable register.
`define MTVEC            12'h305  // Machine trap-handler base address.
`define MCOUNTEREN       12'h306  // Machine counter enable.

// Machine Trap Handling (RW)
`define MSCRATCH         12'h340  // Scratch register for machine trap handlers.
`define MEPC             12'h341  // Machine exception program counter.
`define MCAUSE           12'h342  // Machine trap cause.
`define MTVAL            12'h343  // Machine bad address or instruction.
`define MIP              12'h344  // Machine interrupt pending.


// Supervisor Trap Setup (RW)
`define SSTATUS          12'h100  // Supervisor status register.
`define SEDELEG          12'h102  // Supervisor exception delegation register.
`define SIDELEG          12'h103  // Supervisor interrupt delegation register.
`define SIE              12'h104  // Supervisor interrupt-enable register.
`define STVEC            12'h105  // Supervisor trap-handler base address.
`define SCOUNTEREN       12'h106  // Supervisor counter enable.

// Supervisor Trap Handling (RW)
`define SSCRATCH         12'h140  // Scratch register for supervisor trap handlers.
`define SEPC             12'h141  // Supervisor exception program counter.
`define SCAUSE           12'h142  // Supervisor trap cause.
`define STVAL            12'h143  // Supervisor bad address or instruction.
`define SIP              12'h144  // Supervisor interrupt pending.

// Supervisor Protection and Translation (RW)
`define SATP             12'h180  // Supervisor address translation and protection.


// Machine Memory Protection (RW)
`define PMPCFG0          12'h3a0  // Physical memory protection configuration.
`define PMPCFG1          12'h3a1  // Physical memory protection configuration, RV32 only.
`define PMPCFG2          12'h3a2  // Physical memory protection configuration.
`define PMPCFG3          12'h3a3  // Physical memory protection configuration, RV32 only.
`define PMPADDR0         12'h3b0  // Physical memory protection address register.
`define PMPADDR1         12'h3b1  // Physical memory protection address register.

// Performance counters (RW)
`define MCYCLE          12'hb00  // Raw cycles since start of day
`define MTIME           12'hb01  // "Wall clock", can be aliased to MCYCLE
`define MINSTRET        12'hb02  // Instruction retire count since start of day
`define MHPMCOUNTER3    12'hb03  // WARL (we tie to 0)
`define MHPMCOUNTER4    12'hb04  // WARL (we tie to 0)
`define MHPMCOUNTER5    12'hb05  // WARL (we tie to 0)
`define MHPMCOUNTER6    12'hb06  // WARL (we tie to 0)
`define MHPMCOUNTER7    12'hb07  // WARL (we tie to 0)
`define MHPMCOUNTER8    12'hb08  // WARL (we tie to 0)
`define MHPMCOUNTER9    12'hb09  // WARL (we tie to 0)
`define MHPMCOUNTER10   12'hb0a  // WARL (we tie to 0)
`define MHPMCOUNTER11   12'hb0b  // WARL (we tie to 0)
`define MHPMCOUNTER12   12'hb0c  // WARL (we tie to 0)
`define MHPMCOUNTER13   12'hb0d  // WARL (we tie to 0)
`define MHPMCOUNTER14   12'hb0e  // WARL (we tie to 0)
`define MHPMCOUNTER15   12'hb0f  // WARL (we tie to 0)
`define MHPMCOUNTER16   12'hb10  // WARL (we tie to 0)
`define MHPMCOUNTER17   12'hb11  // WARL (we tie to 0)
`define MHPMCOUNTER18   12'hb12  // WARL (we tie to 0)
`define MHPMCOUNTER19   12'hb13  // WARL (we tie to 0)
`define MHPMCOUNTER20   12'hb14  // WARL (we tie to 0)
`define MHPMCOUNTER21   12'hb15  // WARL (we tie to 0)
`define MHPMCOUNTER22   12'hb16  // WARL (we tie to 0)
`define MHPMCOUNTER23   12'hb17  // WARL (we tie to 0)
`define MHPMCOUNTER24   12'hb18  // WARL (we tie to 0)
`define MHPMCOUNTER25   12'hb19  // WARL (we tie to 0)
`define MHPMCOUNTER26   12'hb1a  // WARL (we tie to 0)
`define MHPMCOUNTER27   12'hb1b  // WARL (we tie to 0)
`define MHPMCOUNTER28   12'hb1c  // WARL (we tie to 0)
`define MHPMCOUNTER29   12'hb1d  // WARL (we tie to 0)
`define MHPMCOUNTER30   12'hb1e  // WARL (we tie to 0)
`define MHPMCOUNTER31   12'hb1f  // WARL (we tie to 0)

`define MCYCLEH         12'hb80  // High halves of each counter
`define MTIMEH          12'hb81 
`define MINSTRETH       12'hb82 
`define MHPMCOUNTER3H   12'hb83 
`define MHPMCOUNTER4H   12'hb84 
`define MHPMCOUNTER5H   12'hb85 
`define MHPMCOUNTER6H   12'hb86 
`define MHPMCOUNTER7H   12'hb87 
`define MHPMCOUNTER8H   12'hb88 
`define MHPMCOUNTER9H   12'hb89 
`define MHPMCOUNTER10H  12'hb8a 
`define MHPMCOUNTER11H  12'hb8b 
`define MHPMCOUNTER12H  12'hb8c 
`define MHPMCOUNTER13H  12'hb8d 
`define MHPMCOUNTER14H  12'hb8e 
`define MHPMCOUNTER15H  12'hb8f 
`define MHPMCOUNTER16H  12'hb90 
`define MHPMCOUNTER17H  12'hb91 
`define MHPMCOUNTER18H  12'hb92 
`define MHPMCOUNTER19H  12'hb93 
`define MHPMCOUNTER20H  12'hb94 
`define MHPMCOUNTER21H  12'hb95 
`define MHPMCOUNTER22H  12'hb96 
`define MHPMCOUNTER23H  12'hb97 
`define MHPMCOUNTER24H  12'hb98 
`define MHPMCOUNTER25H  12'hb99 
`define MHPMCOUNTER26H  12'hb9a 
`define MHPMCOUNTER27H  12'hb9b 
`define MHPMCOUNTER28H  12'hb9c 
`define MHPMCOUNTER29H  12'hb9d 
`define MHPMCOUNTER30H  12'hb9e 
`define MHPMCOUNTER31H  12'hb9f 

`define MCOUNTINHIBIT   12'h302  // WARL (we must tie 0 as CYCLE and TIME are aliased)
`define MHPMEVENT3      12'h323  // WARL (we tie to 0)
`define MHPMEVENT4      12'h324  // WARL (we tie to 0)
`define MHPMEVENT5      12'h325  // WARL (we tie to 0)
`define MHPMEVENT6      12'h326  // WARL (we tie to 0)
`define MHPMEVENT7      12'h327  // WARL (we tie to 0)
`define MHPMEVENT8      12'h328  // WARL (we tie to 0)
`define MHPMEVENT9      12'h329  // WARL (we tie to 0)
`define MHPMEVENT10     12'h32a  // WARL (we tie to 0)
`define MHPMEVENT11     12'h32b  // WARL (we tie to 0)
`define MHPMEVENT12     12'h32c  // WARL (we tie to 0)
`define MHPMEVENT13     12'h32d  // WARL (we tie to 0)
`define MHPMEVENT14     12'h32e  // WARL (we tie to 0)
`define MHPMEVENT15     12'h32f  // WARL (we tie to 0)
`define MHPMEVENT16     12'h330  // WARL (we tie to 0)
`define MHPMEVENT17     12'h331  // WARL (we tie to 0)
`define MHPMEVENT18     12'h332  // WARL (we tie to 0)
`define MHPMEVENT19     12'h333  // WARL (we tie to 0)
`define MHPMEVENT20     12'h334  // WARL (we tie to 0)
`define MHPMEVENT21     12'h335  // WARL (we tie to 0)
`define MHPMEVENT22     12'h336  // WARL (we tie to 0)
`define MHPMEVENT23     12'h337  // WARL (we tie to 0)
`define MHPMEVENT24     12'h338  // WARL (we tie to 0)
`define MHPMEVENT25     12'h339  // WARL (we tie to 0)
`define MHPMEVENT26     12'h33a  // WARL (we tie to 0)
`define MHPMEVENT27     12'h33b  // WARL (we tie to 0)
`define MHPMEVENT28     12'h33c  // WARL (we tie to 0)
`define MHPMEVENT29     12'h33d  // WARL (we tie to 0)
`define MHPMEVENT30     12'h33e  // WARL (we tie to 0)
`define MHPMEVENT31     12'h33f  // WARL (we tie to 0)


`endif
