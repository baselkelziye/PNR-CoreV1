`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/13/2024 03:26:15 AM
// Design Name: 
// Module Name: control_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module control_unit(
    //Komuttan Gelen Sinyaller
    input  [4:0] opcode_i               , 
    input  [2:0] funct3_i               ,
    input  [6:0] funct7_i               ,

    output       reg_write_en_o         , // Register File'e yazma sinyali
    output [1:0] wb_sel_o               , // Yazilacak Veriyi secen mux sinyali
    output [1:0] rs1_pc_imm_sel_o           , // rs1'in PC'den mi yoksa reg_file'dan mi alinacagini belirleyen sinyal
    output [1:0] rs2_imm_csr_sel_o          , // rs2'nin immediate mi yoksa reg'dan mi alinacagini belirleyen sinyal
    output [2:0] imm_type_o             , // Immediate turunu belirleyen sinyal
    output       is_branch_instr_o      , // Branch komutu mu degil mi
    output       is_load_instr_o        , // Load komutu mu degil mi 
    output       is_store_instr_o       , // Store komutu mu degil mi
    output [3:0] alu_op_o               , // ALU islem turunu belirleyen sinyal
    output       unconditional_branch_o , // kosulsuz branch komutu mu degil mi
    output       ex_unit_sel_o          ,
    output       ebreak_trap_o,
    output       ecall_trap_o,
    output       csr_wr_en_o              //Write To CSR
    );

`include "encodings.vh"


/* wb_sel[1:0]
  00 -> Values From ALU
  01 -> Values From Memory (Load)
  10 -> PC + 4 (JAL, JALR)
*/

/*
    imm_type[2:0]
    000 -> LUI, AUIPC
    001 -> JAL
    010 -> STORE
    011 -> BRANCH
    100 -> Signed I-Type
*/

/*
    alu_op[3:0]    
    
        0000 -> ADD
        0001 -> SUB
        0010 -> SLL
        0011 -> SLT
        0100 -> SLTU
        0101 -> XOR
        0110 -> SRL
        0111 -> SRA
        1000 -> OR
        1001 -> AND
        1010 -> LUI
*/

/*
rs1_pc_imm_sel [1:0]
00 -> rs1
01 -> pc
10 -> imm (for csr)

*/

/*
rs2_pc_csr_sel [1:0]
00 -> rs2
01 -> imm
10 -> csr
*/


reg [9:0] control_signals;
localparam [7:0] ILLEGAL = 10'b0_XX_XX_XX_XXX;


reg is_load_instr, is_store_instr, is_branch_instr, unconditional_branch;
reg [3:0] alu_op;

//Select where the EX result is produced (ALU, MDU)
//0 => ALU
//1 => MDU
reg ex_unit_select;
//control_singals = reg_write_en, wb_sel[1:0], rs1_pc_sel, rs2_imm_sel, imm_type[2:0]
reg csr_wr_en;
reg ebreak_trap, ecall_trap;

always @(*)
begin
  //defualt values to not infer latch
  is_load_instr        = 1'b0   ;
  is_store_instr       = 1'b0   ;
  is_branch_instr      = 1'b0   ;
  alu_op               = 4'b0000;
  unconditional_branch = 1'b0   ;
  ex_unit_select       = 1'b0   ;
  csr_wr_en            = 1'b0   ;
  ebreak_trap          = 1'b0   ;
  ecall_trap           = 1'b0   ;
  case(opcode_i)
    `LOAD_OPCODE   : 
    begin
      control_signals = 10'b1_01_00_01_100;
      is_load_instr = 1'b1;
    end
    `STORE_OPCODE  :
    begin
      control_signals = 10'b0_XX_00_01_010;
      is_store_instr = 1'b1;
    end
    `RTYPE_OPCODE  : 
      begin
      control_signals = 10'b1_00_00_00_XXX;
      case(funct7_i) //ADD,SLL,SLT,SLTU,XOR,SRL,OR,AND        
        7'b0000000:
          begin
            case(funct3_i)
              `ADD_FUNCT3 : alu_op = `ADD_ALU_OP;
              `SLL_FUNCT3 : alu_op = `SLL_ALU_OP;
              `SLT_FUNCT3 : alu_op = `SLT_ALU_OP;
              `SLTU_FUNCT3: alu_op = `SLTU_ALU_OP;
              `XOR_FUNCT3 : alu_op = `XOR_ALU_OP;
              `SRL_FUNCT3 : alu_op = `SRL_ALU_OP;
              `OR_FUNCT3  : alu_op = `OR_ALU_OP;
              `AND_FUNCT3 : alu_op = `AND_ALU_OP;                            
              default    : alu_op = `DEFAULT_ALU_OP;
            endcase                                
          end       
        7'b0100000: //SUB,SRA
          begin	
            case(funct3_i)
              `SUB_FUNCT3: alu_op = `SUB_ALU_OP;
              `SRA_FUNCT3: alu_op = `SRA_ALU_OP;
              default   : alu_op = `DEFAULT_ALU_OP;
            endcase 
          end
        7'b0000001: //MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU
          begin
            ex_unit_select = 1'b1;
          end
        default   : alu_op = `DEFAULT_ALU_OP;
      endcase
      end
    `ITYPE_OPCODE  :
    begin
      control_signals = 10'b1_00_00_01_100;
      if(funct3_i == 3'b101) 
        case(funct7_i)
            `SRLI_FUNCT7 : alu_op = `SRL_ALU_OP;
            `SRAI_FUNCT7 : alu_op = `SRA_ALU_OP;
              default: alu_op = `DEFAULT_ALU_OP;
        endcase
      else  //To Add Other I-type extensions, funct3 = 001 needs to be cheked
        case(funct3_i)
          `ADDI_FUNCT3 : alu_op = `ADD_ALU_OP;
          `SLTI_FUNCT3 : alu_op = `SLT_ALU_OP;
          `SLTIU_FUNCT3: alu_op = `SLTU_ALU_OP;
          `XORI_FUNCT3 : alu_op = `XOR_ALU_OP;
          `ORI_FUNCT3  : alu_op = `OR_ALU_OP;
          `ANDI_FUNCT3 : alu_op = `AND_ALU_OP;
          `SLLI_FUNCT3 : alu_op = `SLL_ALU_OP; //If more funct3 = 001 is supported collision might happed and we need to check funct7
        default: alu_op = `DEFAULT_ALU_OP;
        endcase                   
    end
    `BRANCH_OPCODE :
    begin
                    control_signals = 10'b0_XX_01_01_011;
                    is_branch_instr = 1'b1;
    end
    `JALR_OPCODE   :
    begin
                    control_signals = 10'b1_10_00_01_100;
                    unconditional_branch = 1'b1;
                    alu_op = `JALR_ALU_OP;
    end
    `JAL_OPCODE    : 
    begin     
                    control_signals = 10'b1_10_01_01_001;
                    unconditional_branch = 1'b1;
    end
    `LUI_OPCODE    :
    begin
                    control_signals = 10'b1_00_00_01_000;
                    alu_op          = 4'b1010;
    end
    `AUIPC_OPCODE  : control_signals = 10'b1_00_01_01_000;
    `SYSTEM_OPCODE :
    begin 
      //We can use Funct3[2] to differentiate between I instructions
        case (funct3_i) 
          `ECALL,`EBREAK: begin
            
            ebreak_trap = funct7_i[0];
            ecall_trap  = ~funct7_i[0];
          end
          `CSRRW: begin
            csr_wr_en = 1'b1;
            control_signals = 10'b1_00_00_10_XXX;
            alu_op = `ASSIGN_OP;
          end
          `CSRRS: begin
            csr_wr_en = 1'b1;
            control_signals = 10'b1_00_00_10_XXX;
            alu_op = `OR_ALU_OP;
          end
          `CSRRC: begin
            csr_wr_en = 1'b1;
            control_signals = 10'b1_00_00_10_XXX;
            alu_op = `CLEAR_OP;
          end

          `CSRRWI: begin
            csr_wr_en = 1'b1;
            control_signals = 10'b1_00_10_10_101;
            alu_op = `ASSIGN_OP;
          end
          `CSRRSI: begin
            csr_wr_en = 1'b1;
            control_signals = 10'b1_00_10_10_101;
            alu_op = `OR_ALU_OP;
          end
          `CSRRCI: begin
            csr_wr_en = 1'b1;
            control_signals = 10'b1_00_10_10_101;
            alu_op = `CLEAR_OP;
            end 
          default: begin
            csr_wr_en = 1'b0;
            control_signals = ILLEGAL;
            end
          endcase
    end 
    default       : control_signals = ILLEGAL;
  endcase
end

//CSRRW/I => Mapped to Assignment in ALU, CSRRWI as well (in case of x0 field will be 0 so no need extra logic)
//CSRRS/I => Mapped to OR in ALU,
//CSRRC/I => Mapped to Bit Clear in ALU

//CSR instructions Uses the CSR data for RS2, for RS1 it either uses imm or the register, Hence we need to add imm to the mux that selects RS1,PC

assign {reg_write_en_o, wb_sel_o, rs1_pc_imm_sel_o, rs2_imm_csr_sel_o, imm_type_o} = control_signals;
assign is_branch_instr_o = is_branch_instr;
assign is_load_instr_o = is_load_instr;
assign is_store_instr_o = is_store_instr;
assign alu_op_o = alu_op;
assign unconditional_branch_o = unconditional_branch;
assign ex_unit_sel_o  = ex_unit_select;
assign csr_wr_en_o = csr_wr_en;
assign ebreak_trap_o = ebreak_trap;
assign ecall_trap_o = ecall_trap;
endmodule
