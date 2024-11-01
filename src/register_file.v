`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2024 11:23:32 AM
// Design Name: 
// Module Name: register_file
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

// module register_file(
//         input clk_i, rst_i,
//         input [4:0] rd_label_i, rs1_label_i, rs2_label_i,
//         input reg_write_en_i,
//         input  [31:0] rd_data_i,
//         output [31:0] rs1_data_o, rs2_data_o
//     );
    
//     reg [31:0] registers[0:31];
//     integer i;
    
//     always @(posedge rst_i) begin
//         if(rst_i) begin
//             for(i = 0; i < 32; i = i + 1) begin
//                 registers[i] = 32'h0;
//             end
//         end
//     end
    
    
//    always @(negedge clk_i) begin
//         if(reg_write_en_i) begin
//             registers[rd_label_i] <= rd_data_i;
//         end
//    end
   
//   assign rs1_data_o = (rs1_label_i == 5'b0) ? 32'b0 : registers[rs1_label_i];
//   assign rs2_data_o = (rs2_label_i == 5'b0) ? 32'b0 : registers[rs2_label_i];
    
// endmodule


module register_file(
        input clk_i, rst_i,
        input [4:0] rd_label_i, rs1_label_i, rs2_label_i,
        input reg_write_en_i,
        input  [31:0] rd_data_i,
        output [31:0] rs1_data_o, rs2_data_o
    );
    
    reg [31:0] registers[0:31];
    integer i;
    
    always @(negedge clk_i, posedge rst_i) begin
        if(rst_i) begin
            for(i = 0; i < 32; i = i + 1) begin
                registers[i] = 32'h0;
            end
        end else begin
            if(reg_write_en_i && rd_label_i != 5'b0) begin
                registers[rd_label_i] <= rd_data_i;
        end
        end
    end
    

   
  assign rs1_data_o = registers[rs1_label_i];
  assign rs2_data_o = registers[rs2_label_i];
    
endmodule
