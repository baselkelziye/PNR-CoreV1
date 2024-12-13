`timescale 1ns / 1ps

module register_file(
        input clk_i, rst_i,
        input [4:0] rd_label_i, rs1_label_i, rs2_label_i,
        input reg_write_en_i,
        input  [31:0] wr_data_i,
        output [31:0] rs1_data_o, rs2_data_o
);
    
  reg [31:0] registers[0:31];
  integer i;

  always @(posedge clk_i, posedge rst_i)
  begin
    if(rst_i)
    begin
      for(i = 0; i < 32; i = i + 1)
          registers[i] <= 32'h0;
    end else
      begin
          if(reg_write_en_i && rd_label_i != 5'b0) 
            registers[rd_label_i] <= wr_data_i;
      end
  end
  /*
  If WB value matches read value we must forward the WB value
  Writing To registers at neg edge would resolve the issue, due to synthesis issue we are using this approach
  */
  assign rs1_data_o = (rs1_label_i == rd_label_i && reg_write_en_i) ? wr_data_i : registers[rs1_label_i];
  assign rs2_data_o = (rs2_label_i == rd_label_i && reg_write_en_i) ? wr_data_i : registers[rs2_label_i];
    
endmodule
