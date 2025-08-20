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
  input              rst_i         ,
  input      [31:0]  address_i     ,
  input      [31:0]  write_data_i  ,
  input              is_load_instr ,
  input              is_store_instr,
  input      [2:0 ]  funct3_i      ,
  output reg [31:0]  read_data_o
);
parameter MEM_BASE = 32'h00000000;
parameter MEM_SIZE = 32'h200000; // 2 MB is safe for most RISCOF tests
  `include "encodings.vh"
(* verilator public_flat_rw *)
  reg [7:0] cache_r [0:MEM_SIZE-1];

  wire [7:0 ] datum_byte;
  wire [15:0] datum_half;
  wire [31:0] datum_word;    

  wire [31:0] base_addr;
  assign base_addr = address_i - MEM_BASE;

  assign datum_byte = cache_r[base_addr];
  assign datum_half = {cache_r[base_addr + 1], cache_r[base_addr]};
  assign datum_word = {cache_r[base_addr + 3], cache_r[base_addr + 2], cache_r[base_addr + 1], cache_r[base_addr]};

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
  always @ (posedge clk_i, posedge rst_i) begin
    if(rst_i) begin
      for(i = 0; i < MEM_SIZE; i = i+1) begin
          cache_r[i] = 8'h00;
      end
    end else if (is_store_instr) begin
      case (funct3_i)
        `SB_FUNCT3: begin
          cache_r[address_i - MEM_BASE] <= write_data_i[7:0];
        end
  
        `SH_FUNCT3: begin
          cache_r[(address_i - MEM_BASE) + 0] <= write_data_i[7:0];
          cache_r[(address_i - MEM_BASE) + 1] <= write_data_i[15:8];
        end
  
        `SW_FUNCT3: begin
          cache_r[(address_i - MEM_BASE) + 0] <= write_data_i[7:0];
          cache_r[(address_i - MEM_BASE) + 1] <= write_data_i[15:8];
          cache_r[(address_i - MEM_BASE) + 2] <= write_data_i[23:16];
          cache_r[(address_i - MEM_BASE) + 3] <= write_data_i[31:24];
        end
  
        default: begin
          cache_r[(address_i - MEM_BASE) + 0] <= 8'hA5;
          cache_r[(address_i - MEM_BASE) + 1] <= 8'hB6;
          cache_r[(address_i - MEM_BASE) + 2] <= 8'hC7;
          cache_r[(address_i - MEM_BASE) + 3] <= 8'hD8;
        end
      endcase
    end   
  end
endmodule
