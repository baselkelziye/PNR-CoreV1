`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/13/2024 09:40:07 AM
// Design Name: 
// Module Name: instruction_memory_stage
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

//I need to select the data from the PERIPHERAL or the MEMORY

module instruction_memory_stage
(
  input clk_i, rst_i,
  
  //Inputs from Execution stage
  input [31:0] alu_result_mem_i,
  
  input load_store_forward_sel_mem_i, reg_write_en_mem_i,
  input [4:0] rd_label_mem_i,
  input [1:0] wb_sel_mem_i,
  input [31:0] pc_mem_i,
  input [2:0] funct3_mem_i,
  input is_store_mem_i, is_load_mem_i,
  input [31:0] fetched_instruction_mem_i,
  //Value to Store in mem
  input [31:0] latest_rs2_value_mem_i,

  //Outputs to WriteBack Stage
  output reg [31:0] load_value_mem_o,
  output reg [31:0] rd_value_mem_ro,
  output wire [31:0] rd_value_mem_wo,
  output reg [4:0] rd_label_mem_o,
  output reg reg_write_en_mem_o,
  output reg [1:0] wb_sel_mem_o,
  output reg is_load_mem_o,

  
  //Inputs From Writeback stage
  input wire [31:0] load_value_wb_i,
  
  //Wishbone + Peripherals
  output wire peripheral_stall_o,

  output mem_stage_stall_o
);
  //Load-Store Forwarding
  wire [31:0] forwarded_store_value;
  assign forwarded_store_value = (load_store_forward_sel_mem_i) ? load_value_wb_i : latest_rs2_value_mem_i;

  //Wishbone Master Signals.
  wire o_wbm_cyc, o_wbm_stb, o_wbm_we;
  wire [31:0] o_wbm_addr, o_wbm_data;
  wire is_peripheral_access;

  // Wishbone Slave signals
  wire o_wbs_stall, o_wbs_ack;
  wire [31:0] o_wbs_data;
  
  wire [31:0] loaded_data, data_read_from_mem;

  //dcache signals
  wire dcache_stall;
  wire mem_stage_stall;

  //If read from peripheral assign wishbone value
  assign loaded_data = (o_wbs_ack) ? o_wbs_data : data_read_from_mem;

  datum_cache datum_cache_u
  (
      .clk_i(clk_i                       ),
      .rst_i(rst_i                       ),
      .address_i(alu_result_mem_i        ),
      .write_data_i(forwarded_store_value),
      .is_load_instr(is_load_mem_i       ),
      .is_store_instr(is_store_mem_i     ),
      .funct3_i(funct3_mem_i             ),
      .read_data_o(data_read_from_mem    )
  );

  data_mem_subsystem data_mem_subsystem_u
  (
      .clk_i(clk_i                       ),
      .rst_i(rst_i                       ),
      .address_i(alu_result_mem_i        ),
      .write_data_i(forwarded_store_value),
      .is_load_instr(is_load_mem_i       ),
      .is_store_instr(is_store_mem_i     ),
      .funct3_i(funct3_mem_i             ),
      .dcache_stall_o(dcache_stall       ),
      .read_data_o(data_read_from_mem    )
  );

  mux_4x1 #(.DATA_WIDTH(32))
  rd_value_selector_u
  (
    .in0_i(alu_result_mem_i),
    .in1_i(loaded_data     ),
    .in2_i(pc_mem_i + 32'd4        ), // in JAL, JALR. Save next instruction
    .in3_i(32'hA9A9A9A9    ),
    .sel_i(wb_sel_mem_i    ),
    .out_o(rd_value_mem_wo )
  );

  // //Wishbon Master Signals Generation
  // assign is_peripheral_access = (is_load_mem_i || is_store_mem_i) && (alu_result_mem_i[31:28] == 4'b0010);
  // // Start CYC when we have access to peripheral and we don't have ack
  // assign o_wbm_cyc = is_peripheral_access & ~o_wbs_ack; 
  // assign o_wbm_stb = o_wbm_cyc;
  // //Write Enable when we have access to peripheral and we have store instruction
  // assign o_wbm_we = is_peripheral_access & is_store_mem_i;
  // assign o_wbm_addr = alu_result_mem_i;
  // assign o_wbm_data = forwarded_store_value;
  // /* 1- Stall if we have Slave stall (Wait for result)
  //     2- Stall if we have peripheral access and we don't have ack
  // */
  // assign peripheral_stall_o = o_wbs_stall | (is_peripheral_access & ~o_wbs_ack);

  //Wishbon Master Signals Generation
  assign is_peripheral_access = 1'b0;
  // Start CYC when we have access to peripheral and we don't have ack
  assign o_wbm_cyc = 1'b0; 
  assign o_wbm_stb = o_wbm_cyc;
  //Write Enable when we have access to peripheral and we have store instruction
  assign o_wbm_we = 1'b0;
  assign o_wbm_addr = 0;
  assign o_wbm_data = 0;
  /* 1- Stall if we have Slave stall (Wait for result)
      2- Stall if we have peripheral access and we don't have ack
  */
  assign peripheral_stall_o = o_wbs_stall | (is_peripheral_access & ~o_wbs_ack);
  assign mem_stage_stall = dcache_stall;
  assign mem_stage_stall_o = mem_stage_stall;


  wbs_uart wbs_uart_u
  (
    .i_clk(clk_i            ),
    .i_rst(rst_i            ),
    .i_wb_cyc(o_wbm_cyc     ),
    .i_wb_stb(o_wbm_stb     ),
    .i_wb_we(o_wbm_we       ),
    .i_wb_addr(o_wbm_addr   ),
    .i_wb_data(o_wbm_data   ),
    .o_wb_stall(o_wbs_stall ),
    .o_wb_ack(o_wbs_ack     ),
    .o_wb_data(o_wbs_data   )
  );

always @(posedge clk_i, posedge rst_i)
  begin
  if(rst_i | peripheral_stall_o | mem_stage_stall)
    begin //Since Peripheral and Cache Stalls are generated in MEM we need to flush
      load_value_mem_o   <= 32'b0;
      rd_label_mem_o     <= 5'b0 ;
      reg_write_en_mem_o <= 1'b0 ;
      wb_sel_mem_o       <= 2'b0 ;
      is_load_mem_o      <= 1'b0 ;
      rd_value_mem_ro    <= 32'b0;
    end
  else //if(!mem_stage_stall)
    begin
      load_value_mem_o   <= loaded_data       ;
      rd_label_mem_o     <= rd_label_mem_i    ;
      reg_write_en_mem_o <= reg_write_en_mem_i;
      wb_sel_mem_o       <= wb_sel_mem_i      ;
      is_load_mem_o      <= is_load_mem_i     ;
      rd_value_mem_ro    <= rd_value_mem_wo   ;
    end
  end

`ifdef CORE_VERBOSITY
  `define L1_DATA_CACHE_PATH l1_data_cache_u
  wire [8*RISCV_DISASM_STRLEN-1:0] disasm_str = riscv_disasm(fetched_instruction_mem_i, pc_mem_i);
  function void mem_trace_log(int file);
    $fwrite(file,"\n***********Memory Stage****************:");
    $fwrite(file,"\nTime: %1t, Instruction: %0s, Program Counter: 0x%8h", $time, disasm_str,pc_mem_i);
    if(`CORE_VERBOSITY >= 200)begin
      mem_op_trace(file);
    end
    if(`CORE_VERBOSITY >= 400)begin
      data_mem_subsystem_u.data_mem_subsystem_trace_log(file);
    end
  endfunction

  function void mem_op_trace(int file);
    $fwrite(file,"\nTime: %1t, address_i: 0x%8h, write_data_i: 0x%8h, is_load_instr: %b, is_store_instr: %b, funct3_i: %b, read_data_o: 0x%8h",$time,alu_result_mem_i,forwarded_store_value,is_load_mem_i,is_store_mem_i,funct3_mem_i,data_read_from_mem);
  endfunction
`endif

endmodule
