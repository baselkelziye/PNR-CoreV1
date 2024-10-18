`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/13/2024 08:08:15 AM
// Design Name: 
// Module Name: branch_jump
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


module branch_jump(
    input [31:0]in1_i,
    input [31:0]in2_i,
    input is_branch_instr,
    input [2:0] funct3_i,
    output PC_sel_o
    );
    
    wire beq_reg; // BNE bunun degili

    wire blt_reg;// signed Less Than comparison.

    wire bltu_reg; // unsigned

    assign beq_reg =  (in1_i == in2_i ) ? 1 : 0;
    
    assign blt_reg =  ($signed(in1_i  ) < $signed(in2_i  ) ? 1 : 0);
    assign bltu_reg = ($unsigned(in1_i) < $unsigned(in2_i) ? 1 : 0);


    reg out_sel_r;


    
    always @* begin
        case(funct3_i)
            3'b000:
                out_sel_r = beq_reg;
            3'b001:
                out_sel_r = ~beq_reg;
            3'b010:
                out_sel_r = 1'b0;
            3'b011:
                out_sel_r = 1'b1;
            3'b100:
                out_sel_r = blt_reg;
            3'b101: //BGE. EQUAL | !BLT
                out_sel_r = beq_reg | ~blt_reg;
            3'b110:
                out_sel_r = bltu_reg;
            3'b111:
                out_sel_r = beq_reg | ~bltu_reg;
        endcase
    end   
    assign PC_sel_o = out_sel_r;
    
endmodule