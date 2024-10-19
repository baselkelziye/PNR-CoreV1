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
    input  [4:0] opcode_i         , //dismiss lower 2 bits
    input  [2:0] funct3_i         ,
    input  [6:0] funct7_i         ,
    output       reg_write_en_o   ,
    output [1:0] wb_sel_o         ,
    output       rs1_pc_sel_o     ,
    output       rs2_imm_sel_o    ,
    output [2:0] imm_type_o       ,
    output       is_branch_instr_o,
    output       is_load_instr_o  ,
    output       is_store_instr_o ,
    output [3:0] alu_op_o         ,
    output       unconditional_branch_o
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


reg [7:0] control_signals;
localparam [7:0] ILLEGAL = 8'b0_XX_X_X_XXX;


reg is_load_instr, is_store_instr, is_branch_instr, unconditional_branch;
reg [3:0] alu_op;
//control_singals = reg_write_en, wb_sel[1:0], rs1_pc_sel, rs2_imm_sel, imm_type[2:0]



always @(*) begin
    //defualt values to not infer latch
    is_load_instr        = 1'b0   ;
    is_store_instr       = 1'b0   ;
    is_branch_instr      = 1'b0   ;
    alu_op               = 4'b0000;
    unconditional_branch = 1'b0   ;
    case(opcode_i)
        `LOAD_OPCODE   : 
        begin
                        control_signals = 8'b1_01_0_1_100;
                        is_load_instr = 1'b1;
        end
        `STORE_OPCODE  :
        begin
                        control_signals = 8'b0_XX_0_1_010;
                        is_store_instr = 1'b1;
        end
        `RTYPE_OPCODE  : 
            begin
                        control_signals = 8'b1_00_0_0_XXX;
                        case(funct7_i)
                            //ADD,SLL,SLT,SLTU,XOR,SRL,OR,AND
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
                                //SUB,SRA
                            7'b0100000:
                            begin	
                            		case(funct3_i)
                                    `SUB_FUNCT3: alu_op = `SUB_ALU_OP;
                                    `SRA_FUNCT3: alu_op = `SRA_ALU_OP;
                                    default   : alu_op = `DEFAULT_ALU_OP;
                                    endcase 
                            end
                            default   : alu_op = `DEFAULT_ALU_OP;
                            endcase
            end
        `ITYPE_OPCODE  :
        begin
                        control_signals = 8'b1_00_0_1_100;
                        if(funct3_i == 3'b101) begin
                            case(funct7_i)
                                `SRLI_FUNCT7 : alu_op = `SRL_ALU_OP;
                                `SRAI_FUNCT7 : alu_op = `SRA_ALU_OP;
                                 default: alu_op = `DEFAULT_ALU_OP;
                            endcase
                        end else begin //To Add Other I-type extensions, funct3 = 001 needs to be cheked
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
        end
        `BRANCH_OPCODE :
        begin
                        control_signals = 8'b0_XX_1_1_011;
                        is_branch_instr = 1'b1;
        end
        `JALR_OPCODE   :
        begin
                        control_signals = 8'b1_10_0_1_100;
                        unconditional_branch = 1'b1;
        end
        `JAL_OPCODE    : 
        begin     
                        control_signals = 8'b1_10_1_1_001;
                        unconditional_branch = 1'b1;
        end
        `LUI_OPCODE    :
        begin
                        control_signals = 8'b1_00_0_1_000;
                        alu_op          = 4'b1010;
        end
        `AUIPC_OPCODE  : control_signals = 8'b1_00_0_1_000;
        default       : control_signals = ILLEGAL;
    endcase
end

assign {reg_write_en_o, wb_sel_o, rs1_pc_sel_o, rs2_imm_sel_o, imm_type_o} = control_signals;
assign is_branch_instr_o = is_branch_instr;
assign is_load_instr_o = is_load_instr;
assign is_store_instr_o = is_store_instr;
assign alu_op_o = alu_op;
assign unconditional_branch_o = unconditional_branch;



endmodule
