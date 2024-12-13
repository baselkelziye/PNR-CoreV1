`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2024 10:26:49 AM
// Design Name: 
// Module Name: instruction_fetch
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


module instruction_fetch(
  input clk_i, rst_i,
  
  output reg [31:0] fetched_instruction_if_o,
  output reg [31:0] pc_incremented_if_o,

  //Inputs From Decode Stage For load Hazard
  input wire load_stall_if_i,
  
  //Input From Execution Stage
  input wire branching_i, //When we branch we need to NOP the instructions in the PIPELINE
  input wire [31:0] branching_address_i,
  input wire [31:0] pc_ex_i, //This is the PC for the branch instruction in EX Stage


  //Inputs For Branch Prediction.
  input wire is_branch_instr_ex_i,
  input wire decrement_counter_i, increment_counter_i, //we need to 0 the counter on reset

  //Outputs For Branch Prediction
  output reg [31:0] btb_predicted_pc_if_o,
  output reg branch_is_taken_prediction_if_o,

  input wire periheral_stall_if_i
);
    
  reg [31:0] pc_next;
  wire [31:0] fetched_instruction, btb_predicted_pc;
  reg  [31:0] pc_reg;
  wire BTB_hit, branch_is_taken_prediction;
  localparam [31:0] INSTR_NOP = 32'h00000013;
  
  wire if_stage_stall;
  
  assign if_stage_stall = load_stall_if_i | periheral_stall_if_i;
  
  always @(posedge clk_i, posedge rst_i)
  begin
    if(rst_i) 
      pc_reg <=  32'd0;
    else if(!if_stage_stall)
      pc_reg <= pc_next;
  end
    

	
	always @*
  begin
		if(branching_i)  // If we have branch, Then Next shall be the calculated New address adn means we predicted wrong.
			pc_next = branching_address_i;
		 else
      begin
			  if(branch_is_taken_prediction && BTB_hit)
			    pc_next = btb_predicted_pc;
			  else
			    pc_next = pc_reg + 32'd4;
		  end
	end
//    assign pc_next = (branch_is_taken_prediction) ? btb_predicted_pc : pc_reg + 32'd4;

  instr_cache instr_cache_u(
    .pc_i(pc_reg),
    .instr_o(fetched_instruction));

    
  branch_target_buffer #(.N(10))
  BTB(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .pc_i(pc_reg),
    .pc_ex_i(pc_ex_i),
    .btb_address_value_i(branching_address_i),// Branching Adress from ALU
    .update_btb_address_i(is_branch_instr_ex_i & branching_i), //Its Branch in EX, and we are branching update BTB
    .btb_fetched_addres_o(btb_predicted_pc),
    .BTB_hit_o(BTB_hit));

  branch_bits_buffer #(.N(10))
  bimodal_predictor_u(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .pc_i(pc_reg), // we need to increment the PC in the EX STAGE
    .pc_ex_i(pc_ex_i),
    .increment_counter(increment_counter_i),
    .decrement_counter(decrement_counter_i),
    .branch_is_taken(branch_is_taken_prediction));


  always @(posedge clk_i, posedge rst_i)
  begin
    if(rst_i)
      begin
        fetched_instruction_if_o        <= 32'h0;
        pc_incremented_if_o             <= 32'h0;
        branch_is_taken_prediction_if_o <= 1'b0;
        btb_predicted_pc_if_o           <= 32'h0;
      end
    else if(branching_i)
      begin //Flush Sadece Branchte olur simdilik
        fetched_instruction_if_o        <= INSTR_NOP;
        pc_incremented_if_o             <= 32'hDEADC0DE;
        branch_is_taken_prediction_if_o <= 1'b0;
        btb_predicted_pc_if_o           <= 32'h0;
      end
    else if(!if_stage_stall)
      begin
        fetched_instruction_if_o        <= fetched_instruction;
        pc_incremented_if_o 	          <=  pc_reg;
        branch_is_taken_prediction_if_o <= branch_is_taken_prediction;
        btb_predicted_pc_if_o           <= btb_predicted_pc;
      end //If There is stall, Latch the last values (No Change)
  end
    
endmodule
