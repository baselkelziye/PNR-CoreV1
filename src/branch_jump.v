`timescale 1ns / 1ps

`include "encodings.vh"

module branch_jump
(
    input [31:0]  in1_i,
    input [31:0]  in2_i,
    input [2:0 ]  funct3_i,
    output        branch_valid_o
);
    
  wire beq_reg; // BNE bunun degili

  wire blt_reg;// signed Less Than comparison.

  wire bltu_reg; // unsigned

  assign beq_reg =  (in1_i == in2_i ) ? 1 : 0;

  assign blt_reg =  ($signed(in1_i  ) < $signed(in2_i  ) ? 1 : 0);
  assign bltu_reg = ($unsigned(in1_i) < $unsigned(in2_i) ? 1 : 0);

  reg out_sel_r;

always @* begin
    case (funct3_i)
        `BEQ_FUNCT3 :  out_sel_r = beq_reg;         
        `BNE_FUNCT3 :  out_sel_r = ~beq_reg;        
        `BLT_FUNCT3 :  out_sel_r = blt_reg;
        `BGE_FUNCT3 :  out_sel_r = beq_reg | ~blt_reg;  //BGE. EQUAL | !BLT         
        `BLTU_FUNCT3:  out_sel_r = bltu_reg;          
        `BGEU_FUNCT3:  out_sel_r = beq_reg | ~bltu_reg;           
        default     : out_sel_r = 1'b0;
    endcase
end

assign branch_valid_o = out_sel_r;
    
endmodule