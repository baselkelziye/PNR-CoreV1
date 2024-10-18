`timescale 1ns/1ps

module pc_reg(
    input clk_i, rst_i,
    input [31:0] pc_reg_i,
    input en,
    output reg [31:0] pc_reg_o
);


always @(posedge clk_i, posedge rst_i) begin
    if(rst_i) begin
        pc_reg_o <= -32'd4;
    end else if(en)
        pc_reg_o <= pc_reg_i;
end



endmodule