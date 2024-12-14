`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2024 11:18:05 AM
// Design Name: 
// Module Name: instruction_decode
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


module instruction_decode(
  input clk_i, rst_i,
    
  //Inputs from Instruction Fetch Stage
  input [31:0] fetched_instruction_id_i,
  input [31:0] pc_id_i,
	input [31:0] btb_predicted_pc_id_i,
	input 		 branch_is_taken_prediction_id_i,
    
  //Register Related Signals
  output reg [31:0] rs1_data_id_o, rs2_data_id_o,
	output reg [4:0] rd_label_id_o, rs1_label_id_o, rs2_label_id_o,

	//Immediate Value
	output reg [31:0] imm_value_id_o,
	
	//Hazard Detection Unit 
	output reg  load_store_forward_sel_id_o,
	output wire load_stall_id_o,
	//Control Unit
	output reg reg_write_en_id_o, rs1_pc_sel_id_o, rs2_imm_sel_id_o,
	output reg is_branch_instr_id_o, is_store_instr_id_o, is_load_instr_id_o,
	output reg [1:0] wb_sel_id_o,
	output reg [3:0] alu_op_id_o,
	output reg unconditional_branch_id_o,

	//Program Counter
	output reg [31:0] pc_id_o,
	
	//Instruction Extraction
	output reg [2:0] funct3_id_o,

	//Branch Prediction Outputs
	output reg [31:0] btb_predicted_pc_id_o,
	output reg branch_is_taken_prediction_id_o,


	//Inputs From Execution Stage
	input wire is_load_instruction_ex_i,
	input wire [4:0] rd_label_ex_i,
	
	//Inputs From Writeback stage
	input wire reg_write_en_wb_i,
	input wire [4:0] rd_label_wb_i,
	input wire [31:0] rd_value_wb_i,
	
	//Pipeline Control Signals
	input wire branching_id_i,

	//Inputs for Wishbone
	input wire peripheral_stall_id_i
);
    
  //Definitions for Instruction Extraction
  wire [4:0] rd_label, rs1_label, rs2_label;
  wire [2:0] funct3;
  wire [6:0] opcode, funct7;
  
  //Read Register Values
  wire [31:0] rs1_value, rs2_value;
  
  //Immediate Result
  wire [31:0] imm_value;
  
  //Hazard Detection Unit Signals
  wire load_stall, load_store_forward_sel;

	//Control Unit Signals
	wire reg_write_en, rs1_pc_sel, rs2_imm_sel, is_branch_instr;
	wire is_load_instr, is_store_instr;
	wire [1:0] wb_sel;
	wire [2:0] imm_type;
	wire [3:0] alu_op;
	wire	unconditional_branch; 
	wire id_stage_stall;
	wire id_flush;
    
    //Extraction of Instruction fields
  assign rd_label  = fetched_instruction_id_i[11:7];
  assign rs1_label = fetched_instruction_id_i[19:15];
  assign rs2_label = fetched_instruction_id_i[24:20];
  assign funct3    = fetched_instruction_id_i[14:12];
  assign funct7    = fetched_instruction_id_i[31:25];
  assign opcode    = fetched_instruction_id_i[6:0];
    
    
  assign load_stall_id_o = load_stall;
  assign id_stage_stall  =  peripheral_stall_id_i;
  assign id_flush        = load_stall | branching_id_i;

  register_file register_file_u(
  .clk_i(clk_i				          	 ),
  .rst_i(rst_i					           ),
  .rd_label_i(rd_label_wb_i		     ),
	.rs1_label_i(rs1_label		    	 ),
	.rs2_label_i(rs2_label		    	 ),
  .reg_write_en_i(reg_write_en_wb_i), //To be filed from WB Stage
  .wr_data_i(rd_value_wb_i		     ),
  .rs1_data_o(rs1_value			       ),
	.rs2_data_o(rs2_value			       ));
        
        
  imm_gen imm_gen_u(
    .instr_i(fetched_instruction_id_i),
    .imm_src(imm_type				  ), 
    .imm_o(imm_value				  ));
    
  hazard_detection_unit hazard_detection_unit_u(
	.is_load_instruction_ex_i(is_load_instruction_ex_i),  
	.is_store_instruction_id_i(is_store_instr		      ), 
	.rd_label_ex_i(rd_label_ex_i					            ),
	.rs1_label_id_i(rs1_label					            	  ),
	.rs2_label_id_i(rs2_label					            	  ), 
	.stall_o(load_stall							              	  ),
	.load_store_forward_sel_o(load_store_forward_sel  ));


	control_unit control_unit_u(
	.opcode_i(opcode[6:2]						            ), //dismiss lower 2 bits
  .funct3_i(funct3							              ),
  .funct7_i(funct7							              ),
  .reg_write_en_o(reg_write_en				        ),
  .wb_sel_o(wb_sel							              ),
  .rs1_pc_sel_o(rs1_pc_sel					          ),
  .rs2_imm_sel_o(rs2_imm_sel					        ),
  .imm_type_o(imm_type						            ),
  .is_branch_instr_o(is_branch_instr			    ),
  .is_load_instr_o(is_load_instr				      ),
  .is_store_instr_o(is_store_instr		      	),
  .alu_op_o(alu_op						      	        ),
	.unconditional_branch_o(unconditional_branch));
   
   
  always @(posedge clk_i, posedge rst_i)
  begin
    if(rst_i)
    begin 
      rs1_data_id_o   	          		 <= 32'h0 ;
      rs2_data_id_o   		          	 <= 32'h0 ;
			imm_value_id_o           		  	 <= 32'h0 ;
			load_store_forward_sel_id_o      <= 1'b0  ;
			reg_write_en_id_o 	        		 <= 1'b0  ;
			rs1_pc_sel_id_o 		          	 <= 1'b0  ;
			rs2_imm_sel_id_o 		             <= 1'b0  ;
			is_branch_instr_id_o 		         <= 1'b0  ;
			is_store_instr_id_o 	           <= 1'b0  ;
			is_load_instr_id_o          		 <= 1'b0  ;
			wb_sel_id_o 				             <= 2'b00 ;
			alu_op_id_o 				             <= 4'b0  ;
			pc_id_o 			               		 <= -32'h4;
			rd_label_id_o 			             <= 5'b0  ;
			rs1_label_id_o 		          	   <= 5'b0  ;
			rs2_label_id_o 		          	   <= 5'b0  ;	
			funct3_id_o 				             <= 3'b0  ;	
			unconditional_branch_id_o        <= 1'b0  ;
			btb_predicted_pc_id_o 		       <= 32'h0 ;
			branch_is_taken_prediction_id_o  <= 1'b0  ;      
    end 
    else if(id_flush)
    begin // Komutu NOP'A cevirmek icin bunlar ytrli
      reg_write_en_id_o 				      <= 1'b0 ;
      is_store_instr_id_o 			      <= 1'b0 ;
      is_branch_instr_id_o 			      <= 1'b0 ;
      is_load_instr_id_o				      <= 1'b0 ;
			unconditional_branch_id_o 		  <= 1'b0 ;
			btb_predicted_pc_id_o 			    <= 32'h0;
			branch_is_taken_prediction_id_o <= 1'b0 ;     
    end
    else if(!id_stage_stall)
    begin // If stall generated else where (Peripheral Etc, Don't insert NOP)
      rs1_data_id_o  			            <= rs1_value			       			    ;
      rs2_data_id_o  			            <= rs2_value			  			        ; 
      imm_value_id_o 			            <= imm_value			  			        ; 
      load_store_forward_sel_id_o     <= load_store_forward_sel			    ;
      reg_write_en_id_o 			        <= reg_write_en   		  			    ;
      rs1_pc_sel_id_o 			          <= rs1_pc_sel	   		  			      ;
      rs2_imm_sel_id_o 			          <= rs2_imm_sel	   		  			    ;
      is_branch_instr_id_o		        <= is_branch_instr		  			    ;
      is_store_instr_id_o 		        <= is_store_instr 		  			    ;
      is_load_instr_id_o 		          <= is_load_instr  		  			    ;
      wb_sel_id_o 				            <= wb_sel	 			  			          ;
      alu_op_id_o 				            <= alu_op	 			  			          ;
      pc_id_o               				 	<= pc_id_i  			  			        ;
      rd_label_id_o 				          <= rd_label 			  			        ;
      rs1_label_id_o				          <= rs1_label			  			        ;
      rs2_label_id_o				          <= rs2_label			  			        ;
      funct3_id_o   				          <= funct3   			  			        ;
      unconditional_branch_id_o       <= unconditional_branch  			    ;
      btb_predicted_pc_id_o 		      <= btb_predicted_pc_id_i			    ;
      branch_is_taken_prediction_id_o <= branch_is_taken_prediction_id_i;
		end 
  end

endmodule
