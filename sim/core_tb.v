`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2024 08:16:54 AM
// Design Name: 
// Module Name: core_tb
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


module core_tb();

localparam T=20;
reg clk_i, rst_i;

core dut(.clk_i(clk_i), .rst_i(rst_i));

always 
begin
    clk_i = 1'b1;
    #(T/2);
    clk_i = 1'b0;
    #(T/2);
end


initial begin
	#2;
    rst_i = 1'b1;
    #(T+ 2);
    rst_i = 1'b0;
end



endmodule
