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
`define DEFAULT_ALU_OP      4'b1111
`endif
