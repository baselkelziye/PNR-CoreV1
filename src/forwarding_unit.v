
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
  input       [4:0] rd_label_ex_mem_o, // MEM RD Label
  input       [4:0] rd_label_mem_wb_o, // WB  RD Label
  input       [4:0] rd_label_id_ex_o , // EX RD Label

  input       [4:0] rs1_label_id_i, //rs1 Label in Decode
  input       [4:0] rs2_label_id_i, // rs2 Label in Decode
  input             reg_wb_en_ex_mem_o, // Mem Reg en
  input             reg_wb_en_mem_wb_o, // Wb Reg en
  input             reg_wb_en_id_ex_o , // EX reg en

  output reg  [1:0] forwardA_o,
  output reg  [1:0] forwardB_o
);


localparam [1:0] NO_FORWARDING = 2'b00,
                 FORWARD_EX    = 2'b01,
                 FORWARD_MEM   = 2'b10,
                 FORWARD_WB    = 2'b11;

wire rs1_mem_match, rs1_wb_match, rs1_ex_match;
assign rs1_mem_match = (rd_label_ex_mem_o != 5'b0 && reg_wb_en_ex_mem_o && rd_label_ex_mem_o == rs1_label_id_i);  
assign rs1_wb_match  = (rd_label_mem_wb_o != 5'b0 && reg_wb_en_mem_wb_o && rd_label_mem_wb_o == rs1_label_id_i);
assign rs1_ex_match  = (rd_label_id_ex_o  != 5'b0 && reg_wb_en_id_ex_o  && rd_label_id_ex_o  == rs1_label_id_i);

wire rs2_mem_match, rs2_wb_match, rs2_ex_match;
assign rs2_mem_match = (rd_label_ex_mem_o != 5'b0 && reg_wb_en_ex_mem_o && rd_label_ex_mem_o == rs2_label_id_i);
assign rs2_wb_match  = (rd_label_mem_wb_o != 5'b0 && reg_wb_en_mem_wb_o && rd_label_mem_wb_o == rs2_label_id_i);
assign rs2_ex_match  = (rd_label_id_ex_o  != 5'b0 && reg_wb_en_id_ex_o  && rd_label_id_ex_o  == rs2_label_id_i);

always @(*)
  begin
    if(rs1_ex_match)
      forwardA_o = FORWARD_EX;
    else if (rs1_mem_match) 
      forwardA_o = FORWARD_MEM;     //RS1 = EX/MEM RD
    else if(rs1_wb_match && !rs1_mem_match)  //Buraya geldigimize gore ztn EX/MEM de forwarding yok ama yine de konsepti anlamak icin yazdim.         
      forwardA_o = FORWARD_WB; 
    else //no forwarding            
      forwardA_o = NO_FORWARDING; 
end
      
    //every thing is the same here but instead of rs1, we compare RS2
  always @(*) begin
  if (rs2_ex_match)
    forwardB_o = FORWARD_EX;
  else if (rs2_mem_match) 
    forwardB_o = FORWARD_MEM;//RS2 = EX/MEM RD
  else if(rs2_wb_match && !rs2_mem_match)   //Buraya geldigimize gore ztn EX/MEM de forwarding yok ama yine de konsepti anlamak icin yazdim.
    forwardB_o = FORWARD_WB; 
  else //no forwarding            
    forwardB_o = NO_FORWARDING; 
  end

endmodule
