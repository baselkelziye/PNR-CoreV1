
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

//Forwarding unit.
//Result from load instruction is forwarded when ForwardA/B is  = 3 (2'b11)
//Since load instruction's value can be forwarded only from mem/wb stage (load hazard) only that case is checked.
//we add is_load_instr_wb_i to check if the instruction is load, if yes we forward the value from LOAD, if its not we pass alu result.
//ex/mem is simple. not addition logic needed.
//////////////////////////////////////////////////////////////////////////////////


module forwarding_unit
(
  input       [4:0] rd_label_ex_mem_o,
  input       [4:0] rd_label_mem_wb_o,
  input       [4:0] rs1_label_id_ex_o,
  input       [4:0] rs2_label_id_ex_o,
  input             reg_wb_en_ex_mem_o,
  input             reg_wb_en_mem_wb_o,
  output reg  [1:0] forwardA,
  output reg  [1:0] forwardB
);


localparam [1:0] NO_FORWARDING  = 2'b00,
                 FORWARD_WB     = 2'b01,
                 FORWARD_MEM    = 2'b10,
                 FORWARD_BUG    = 2'b11;


wire rs1_mem_match, rs1_wb_match;
assign rs1_mem_match = (rd_label_ex_mem_o != 5'b0 && reg_wb_en_ex_mem_o && rd_label_ex_mem_o == rs1_label_id_ex_o);  
assign rs1_wb_match  = (rd_label_mem_wb_o != 5'b0 && reg_wb_en_mem_wb_o && rd_label_mem_wb_o == rs1_label_id_ex_o);

wire rs2_mem_match, rs2_wb_match;
assign rs2_mem_match = (rd_label_ex_mem_o != 5'b0 && reg_wb_en_ex_mem_o && rd_label_ex_mem_o == rs2_label_id_ex_o);
assign rs2_wb_match  = (rd_label_mem_wb_o != 5'b0 && reg_wb_en_mem_wb_o && rd_label_mem_wb_o == rs2_label_id_ex_o);

  always @(*)
  begin
    if (rs1_mem_match) 
      forwardA = FORWARD_MEM;     //RS1 = EX/MEM RD
    else if(rs1_wb_match && !rs1_mem_match)  //Buraya geldigimize gore ztn EX/MEM de forwarding yok ama yine de konsepti anlamak icin yazdim.         
      forwardA = FORWARD_WB; 
    else //no forwarding            
      forwardA = NO_FORWARDING; 
  end
      
    //every thing is the same here but instead of rs1, we compare RS2
  always @(*) begin
  if (rs2_mem_match) 
    forwardB = FORWARD_MEM;//RS2 = EX/MEM RD
  else if(rs2_wb_match && !rs2_mem_match)   //Buraya geldigimize gore ztn EX/MEM de forwarding yok ama yine de konsepti anlamak icin yazdim.
    forwardB = FORWARD_WB; 
  else //no forwarding            
    forwardB = NO_FORWARDING; 
  end

endmodule
