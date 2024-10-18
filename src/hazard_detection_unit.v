`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/13/2024 02:57:49 AM
// Design Name: 
// Module Name: hazard_detection_unit
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


module hazard_detection_unit(
    input is_load_instruction_ex_i,
    input is_store_instruction_id_i,
    input [4:0] rd_label_ex_i,
    input [4:0] rs1_label_id_i,
    input [4:0] rs2_label_id_i, 

    output reg stall_o,
    output reg load_store_forward_sel_o
);

   always @(*) begin
      stall_o = 1'b0;
      load_store_forward_sel_o = 1'b0;
      if (is_load_instruction_ex_i) begin
         if (rd_label_ex_i != 5'b00000) begin
            if (((rs1_label_id_i == rd_label_ex_i) || (rs2_label_id_i == rd_label_ex_i))) begin
                if(is_store_instruction_id_i) begin //Load-Store Forward situation
                    stall_o = 1'b0;
                    load_store_forward_sel_o = 1'b1;
                end else begin
                    stall_o = 1'b1;
                    load_store_forward_sel_o = 1'b0;
                end
            end 
         end
      end
   end



endmodule
