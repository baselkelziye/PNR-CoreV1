`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/13/2024 08:06:29 AM
// Design Name: 
// Module Name: ALU
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


module ALU
  (
    input [31:0]  alu1_i,
    input [31:0]  alu2_i,
    input [3:0]   alu_op_i,
    output [31:0] result_o
  );
  
  /*
  0000 ADD
  0001 SUB
  0010 SLL
  0011 SLT
  0100 SLTU
  0101 XOR
  0110 SRL
  0111 SRA
  1000 OR
  1001 AND
  1010 LUI
  */        
        
  `include "encodings.vh"
  reg [31:0]result_r; 
        
  always @ (*)
  begin
    case (alu_op_i)
      `ADD_ALU_OP :  result_r = alu1_i + alu2_i;
      `SUB_ALU_OP :  result_r = alu1_i - alu2_i;
      `SLL_ALU_OP :  result_r = alu1_i << alu2_i[4:0];
      `SLT_ALU_OP :  result_r = $signed(alu1_i) < $signed(alu2_i) ? 1 : 0;
      `SLTU_ALU_OP:  result_r = alu1_i < alu2_i ? 1 : 0;
      `XOR_ALU_OP :  result_r = alu1_i ^ alu2_i;
      `SRL_ALU_OP :  result_r = alu1_i >> alu2_i[4:0];
      `SRA_ALU_OP :  result_r = $signed(alu1_i) >>> alu2_i[4:0];
      `OR_ALU_OP  :  result_r = alu1_i | alu2_i;
      `AND_ALU_OP :  result_r = alu1_i & alu2_i;
      `LUI_ALU_OP :  result_r = alu2_i;
      `JALR_ALU_OP:  result_r = (alu1_i + alu2_i) & 32'hfffffffe; //Set lsb to zero
      default     :  result_r = 32'hdeadbeef;
    endcase
  end   

  assign result_o = result_r;


`ifdef CORE_VERBOSITY
  function void alu_trace_log(int file);
    // $fwrite(file,"\nALU");
    $fwrite(file, "\nTime: %1t ALU, alu1_i: 0x%8h, alu2_i: 0x%8h, alu_op_i: %0b,  result_o: 0x%8h",$time,alu1_i,alu2_i,alu_op_i,result_o);
  endfunction
`endif 

endmodule
