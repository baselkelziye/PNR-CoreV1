`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/01/2024 06:10:23 AM
// Design Name: 
// Module Name: BHT
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


module branch_bits_buffer
#(parameter N=10) // Size of BHT and BTB
(
    input clk_i,rst_i,
    input [31:0] pc_i,
    input [31:0] pc_ex_i, // Yazma Islemi Buna gore yapilacak
    input increment_counter,
    input decrement_counter,
    output branch_is_taken
    
);
    
localparam [1:0]

  STRONGLY_NOT_TAKEN = 2'b00,
  WEAKLY_NOT_TAKEN   = 2'b01,
  WEAKLY_TAKEN       = 2'b10,
  STRONGLY_TAKEN     = 2'b11;

  wire [1:0] if_pc_counter_2bit_counter, ex_pc_2bit_counter;
  reg [1:0] branch_history_buffer[2**N-1:0]; 

  integer i;

  assign ex_pc_2bit_counter = branch_history_buffer[pc_ex_i[N:2]];
  assign if_pc_counter_2bit_counter = branch_history_buffer[pc_i[N:2]];

  always @(posedge clk_i, posedge rst_i)
  begin //might need to add IF branch instr
    if(rst_i)
      for(i = 0; i < 2**N; i = i + 1)
          branch_history_buffer[i] <= STRONGLY_NOT_TAKEN;
    else
    begin
      if(ex_pc_2bit_counter != STRONGLY_TAKEN && increment_counter)
          branch_history_buffer[pc_ex_i[N:2]] <= branch_history_buffer[pc_ex_i[N:2]] + 2'b1;
      else if( ex_pc_2bit_counter != STRONGLY_NOT_TAKEN && decrement_counter)
          branch_history_buffer[pc_ex_i[N:2]] <= branch_history_buffer[pc_ex_i[N:2]] - 2'b1;
    end
  end

    
    assign branch_is_taken = (pc_i < 30'd1024) ? if_pc_counter_2bit_counter[1]: 1'b0;
endmodule
