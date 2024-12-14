`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/14/2024 01:20:37 AM
// Design Name: 
// Module Name: datum_cache
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


module datum_cache
(
  input              clk_i         ,
  input      [31:0]  address_i     ,
  input      [31:0]  write_data_i  ,
  input              is_load_instr ,
  input              is_store_instr,
  input      [2:0 ]  funct3_i      ,
  output reg [31:0]  read_data_o
);
  `include "encodings.vh"
  reg[7:0] cache_r[0:1023];
  wire [7:0 ] datum_byte;
  wire [15:0] datum_half;
  wire [31:0] datum_word;    

  assign datum_byte = cache_r[address_i[9:0]];
  assign datum_half = {cache_r[{address_i[9:1],1'b1}], datum_byte};
  assign datum_word = {cache_r[{address_i[9:2],2'b11}], cache_r[{address_i[9:2], 2'b10}], datum_half};

  always @ (*)
  begin
    if(is_load_instr) 
      case(funct3_i)
        `LB_FUNCT3 : read_data_o = {{24{datum_byte[7]}}, datum_byte};
        `LH_FUNCT3 : read_data_o = {{16{datum_half[15]}}, datum_half};
        `LW_FUNCT3 : read_data_o = datum_word;
        `LBU_FUNCT3: read_data_o = {24'b0, datum_byte};
        `LHU_FUNCT3: read_data_o = {16'b0, datum_half};
        default: read_data_o = 32'hA5B5C5D5;
      endcase
    else
      read_data_o = 32'hB1B1B1B1;
  end
    
  integer i;
  always @ (posedge clk_i)
  begin          
    if(is_store_instr) 
      case(funct3_i)
        `SB_FUNCT3:
            cache_r[address_i[31:0]] <= write_data_i[7:0];
        `SH_FUNCT3: begin
            cache_r[{address_i[31:1],1'b0}] <= write_data_i[7:0];
            cache_r[{address_i[31:1],1'b1}] <= write_data_i[15:8];
        end
        `SW_FUNCT3: begin
            cache_r[{address_i[31:2],{2'b00}}] <= write_data_i[7:0];
            cache_r[{address_i[31:2],{2'b01}}] <= write_data_i[15:8];
            cache_r[{address_i[31:2],{2'b10}}] <= write_data_i[23:16];
            cache_r[{address_i[31:2],{2'b11}}] <= write_data_i[31:24];
        end
        default : begin //This needs to be handled in the future
            cache_r[{address_i[31:2],{2'b00}}] <= 8'hA5;
            cache_r[{address_i[31:2],{2'b01}}] <= 8'hB6;
            cache_r[{address_i[31:2],{2'b10}}] <= 8'hC7;
            cache_r[{address_i[31:2],{2'b11}}] <= 8'hD8;
        end
      endcase   
  end   
endmodule
