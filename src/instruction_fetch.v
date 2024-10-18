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
        input wire branching_i,
        input wire [31:0] branching_address_i
    );
    
    wire [31:0] pc;
    wire [31:0] fetched_instruction, pc_incremented;
    localparam [31:0] INSTR_NOP = 32'h00000013;
    pc_reg pc_reg_u
(
    .clk_i(clk_i),
    .rst_i(rst_i),
     .pc_reg_i(pc),
     .en(!load_stall_if_i), 
     .pc_reg_o(pc_incremented)
);

assign pc = (branching_i) ? branching_address_i : pc_incremented + 32'd4;

instr_cache instr_cache_u(.pc_i(pc_incremented),.instr_o(fetched_instruction));


always @(posedge clk_i, posedge rst_i) begin
	if(rst_i) begin
		fetched_instruction_if_o <= 32'h0;
		pc_incremented_if_o <= 32'h0;
	end else if(branching_i)begin
		fetched_instruction_if_o <= INSTR_NOP;
		pc_incremented_if_o <= 32'hDEADC0DE;
	end else if(!load_stall_if_i) begin
		fetched_instruction_if_o <= fetched_instruction;
		pc_incremented_if_o 	 <=  pc_incremented;
	end //If There is stall, Latch the last values (No Change)
end
    
endmodule
