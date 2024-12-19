`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/01/2024 04:14:27 AM
// Design Name: 
// Module Name: BTB
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


module branch_target_buffer
#(parameter N = 10)
(
	input clk_i, rst_i,
	input [31:0] pc_i,
	input [31:0] pc_ex_i, // This is the PC for the branch instr
	input [31:0] btb_address_value_i, // Alu Res from EX
	
	input update_btb_address_i, // Is Branch From EX
	
	output [31:0] btb_fetched_addres_o,
	output BTB_hit_o // 
    );
    
  reg [31:0]  BTB[2**N-1:0];
    
  integer i;

	always @(posedge clk_i, posedge rst_i)
  begin
    if(rst_i)
      for(i = 0; i < 2**N; i = i + 1)
        BTB[i] <= 32'h0;
    else
		  if(update_btb_address_i) 
			  BTB[pc_ex_i[N:2]] <= btb_address_value_i;
	end

  assign btb_fetched_addres_o = BTB[pc_i[N:2]];
	assign BTB_hit_o = (BTB[pc_i[N:2]] != 32'h0);
    
endmodule
