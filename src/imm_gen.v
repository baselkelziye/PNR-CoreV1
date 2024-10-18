`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/13/2024 01:59:10 AM
// Design Name: 
// Module Name: imm_gen
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


`timescale 1ns / 1ps

module imm_gen(
    input [31:0] instr_i,  // Use the full 32-bit instruction as input
    input [2:0] imm_src,
    output [31:0] imm_o
    );
    
    reg [31:0] imm_r; 

    always @* begin
        case (imm_src)
            3'b000: imm_r = {instr_i[31:12], 12'h0}; // U-immediate (LUI)
            3'b001: imm_r = {{12{instr_i[31]}}, instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0}; // JAL
            3'b010: imm_r = {{21{instr_i[31]}}, instr_i[30:25], instr_i[11:7]};  // S-immediate (STORE)
            3'b011: imm_r = {{20{instr_i[31]}}, instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0}; // B-immediate (Branch)
            3'b100: imm_r = {{21{instr_i[31]}}, instr_i[31:20]}; //  I-immediate (Load, JALR, addi)
            default: imm_r = 32'h0;
        endcase
    end
    
    assign imm_o = imm_r;
    
endmodule
