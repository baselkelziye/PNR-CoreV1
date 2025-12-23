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
#(
  parameter D_WORDS_PER_LINE = 4,
  parameter DATA_WIDTH = 32
)
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
  input [31:0] rs1_mem_i,
  input [31:0] latest_rs2_value_mem_i,
  output reg [31:0] rs1_mem_o,
  output reg [31:0] rs2_mem_o,
  input [7:0] sb_id_mem_i,
  output reg [31:0] alu_result_mem_o,

  //CSR Unit Inputs
  input csr_wr_en_mem_i,
  input ecall_trap_mem_i,
  input ebreak_trap_mem_i,
  output reg ecall_trap_mem_o,
  output reg ebreak_trap_mem_o,
  input sret_trap_mem_i,
  output reg sret_trap_mem_o,
  input itlb_miss_mem_i,
  output reg itlb_miss_mem_o,
  input itlb_wr_en_mem_i,
  input dtlb_wr_en_mem_i,
  output reg itlb_wr_en_mem_o,
  output reg dtlb_wr_en_mem_o,
  output reg load_page_fault_mem_o,
  output reg store_page_fault_mem_o,
  //Outputs to WriteBack Stage
  output reg [31:0] load_value_mem_o,
  output reg [31:0] rd_value_mem_ro,
  output wire [31:0] rd_value_mem_wo,
  output reg [4:0] rd_label_mem_o,
  output reg reg_write_en_mem_o,
  output reg [1:0] wb_sel_mem_o,
  output reg is_load_mem_o,
  output reg [31:0] pc_mem_o,
  
  //Inputs From Writeback stage
  input wire [31:0] load_value_wb_i, 

  //Outputs to Trap/CSR
  output reg csr_wr_en_mem_o,
  input [11:0] csr_addr_mem_i,
  output reg [11:0] csr_addr_mem_o,
  input [31:0] csr_rd_value_mem_i,
  output reg [31:0] csr_rd_value_mem_o,
  input trap_en_mem_i, //This is a trap from WB
  input [1:0] execution_mode_mem_i,

  //ROB signals
  input [3:0] rob_tag_mem_i,
  output reg [3:0] rob_tag_mem_o,
  input instr_valid_mem_i,
  output reg instr_valid_mem_o,
  
  //Wishbone + Peripherals
  output wire peripheral_stall_o,

  output reg [31:0] fetched_instruction_mem_o,
  output mem_stage_stall_o,

  //dcache request handshake
  output dcache_req_valid_mem_o,
  input  dcache_req_valid_mem_i,
  output [29:0] dcache_address_mem_o,
  output dcache_rd_wr_mem_o,
  //-------------------------------------------
  input dcache_resp_valid_mem_i,
  input ram_response_id_mem_i,
  output dcache_data_ready_mem_o,
  input [DATA_WIDTH-1:0] dcache_line_fill_mem_i[0:D_WORDS_PER_LINE-1],
  output [DATA_WIDTH-1:0] dcache_line_evict_mem_o [0:D_WORDS_PER_LINE-1]

);


  //Since memory writes take more than 1 clock cycles,
  //When we stall at MEM stage, WB continue to execute, hence when we are going to write our value to cache array we will not be able to 
  // have the correct value from WB, hence we need to latch it!
  // reg [31:0] forwarded_store_value;
  // always @(posedge clk_i) begin
  //   if(rst_i) begin
  //     forwarded_store_value <= '0;
  //   end else if(load_store_forward_sel_mem_i) begin
  //     forwarded_store_value <= load_value_wb_i;
  //   end else begin
  //     forwarded_store_value <= latest_rs2_value_mem_i;
  //   end
  // end

  //Wishbone Master Signals.
  wire o_wbm_cyc, o_wbm_stb, o_wbm_we;
  wire [31:0] o_wbm_addr, o_wbm_data;
  wire is_peripheral_access;

  // Wishbone Slave signals
  wire o_wbs_stall, o_wbs_ack;
  wire [31:0] o_wbs_data;
  
  wire [31:0] loaded_data, data_read_from_mem;

  //dcache signals
  wire data_subsystem_stall;
  wire mem_stage_stall;

  //CSR values
  wire [31:0] csr_rd_value;
  wire load_page_fault, store_page_fault;
  wire [31:0] dtlb_data, pa_dtlb;

  //dtlb signals
  wire dtlb_hit_o;
  //If read from peripheral assign wishbone value
  assign loaded_data = (o_wbs_ack) ? o_wbs_data : data_read_from_mem;
  localparam DTLB_ENTRIES = 32;
  
  dtlb #(
    .DTLB_ENTRIES(DTLB_ENTRIES),
    .DATA_WIDTH(DATA_WIDTH)
  )
  dtlb_u(
    .clk_i              (   clk_i                  ),
    .rst_i              (   rst_i                  ),
    //DTLB Write Signals
    .dtlb_wr_en_i       (   dtlb_wr_en_mem_i       ),
    .rs1_i              (   rs1_mem_i              ),
    .rs2_i              (   latest_rs2_value_mem_i ),
    //Translation Signals
    .alu_result_i       (   alu_result_mem_i       ), //Virtual Address
    .is_load_mem_i      (   is_load_mem_i          ),
    .is_store_mem_i     (   is_store_mem_i         ),
    .execution_mode_i   (   execution_mode_mem_i   ),
    //Outputs
    .load_page_fault_o  (   load_page_fault        ),
    .store_page_fault_o (   store_page_fault       ),
    .dtlb_data_o        (   dtlb_data              ),
    .pa_dtlb_o          (   pa_dtlb                ),
    .dtlb_hit_o         (   dtlb_hit_o             )
  );

  data_mem_subsystem data_mem_subsystem_u
  (
      .clk_i                      (   clk_i                   ),
      .rst_i                      (   rst_i                   ),
      .address_i                  (   pa_dtlb                 ),
      .write_data_i               (   latest_rs2_value_mem_i  ),
      .is_load_instr              (   is_load_mem_i           ),
      .is_store_instr             (   is_store_mem_i          ),
      .trap_en_mem_i              (ebreak_trap_mem_i | ecall_trap_mem_i | itlb_miss_mem_i | load_page_fault | store_page_fault), // If we have Exception, Don't Do mem op
      .trap_en_wb_i               (   trap_en_mem_i           ), //This signal comes from WB to MEM stage,
      .funct3_i                   (   funct3_mem_i            ),
      .sb_id_i                    (   sb_id_mem_i             ),
      .data_mem_subsystem_stall_o (   data_subsystem_stall    ),
      .read_data_o                (   data_read_from_mem      ),
      //dcache request handshake
      .dcache_req_valid_o(dcache_req_valid_mem_o),
      .dcache_req_ready_i(dcache_req_valid_mem_i),
      .dcache_address_o(dcache_address_mem_o),
      .dcache_rd_wr_o(dcache_rd_wr_mem_o),
      //-------------------------------------------
      //dcache respond handshake
      .dcache_resp_valid_i(dcache_resp_valid_mem_i),
      .ram_response_id_i(ram_response_id_mem_i),
      .dcache_data_ready_o(dcache_data_ready_mem_o),
      .dcache_line_fill_i(dcache_line_fill_mem_i),
      .dcache_line_evit_o(dcache_line_evict_mem_o),
      //dtlb interface
      .dtlb_hit_i(dtlb_hit_o)
  );


  mux_4x1 #(.DATA_WIDTH(32))
  rd_value_selector_u
  (
    .in0_i  (   alu_result_mem_i  ),
    .in1_i  (   loaded_data       ),
    .in2_i  (   pc_mem_i + 32'd4  ), // in JAL, JALR. Save next instruction
    .in3_i  (   32'hA9A9A9A9      ), // CSR
    .sel_i  (   wb_sel_mem_i      ),
    .out_o  (   rd_value_mem_wo   )
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
  assign mem_stage_stall = data_subsystem_stall & ~trap_en_mem_i;
  assign mem_stage_stall_o = mem_stage_stall;


  // wbs_uart wbs_uart_u
  // (
  //   .i_clk(clk_i            ),
  //   .i_rst(rst_i            ),
  //   .i_wb_cyc(o_wbm_cyc     ),
  //   .i_wb_stb(o_wbm_stb     ),
  //   .i_wb_we(o_wbm_we       ),
  //   .i_wb_addr(o_wbm_addr   ),
  //   .i_wb_data(o_wbm_data   ),
  //   .o_wb_stall(o_wbs_stall ),
  //   .o_wb_ack(o_wbs_ack     ),
  //   .o_wb_data(o_wbs_data   )
  // );

always @(posedge clk_i, posedge rst_i)
  begin
  if(rst_i | peripheral_stall_o | mem_stage_stall | trap_en_mem_i)
    begin //Since Peripheral and Cache Stalls are generated in MEM we need to flush
      load_value_mem_o   <= 32'b0;
      rd_label_mem_o     <= 5'b0 ;
      reg_write_en_mem_o <= 1'b0 ;
      wb_sel_mem_o       <= 2'b0 ;
      is_load_mem_o      <= 1'b0 ;
      rd_value_mem_ro    <= 32'b0;
      fetched_instruction_mem_o <= 32'h13;
      csr_wr_en_mem_o      <= 1'b0;
      csr_addr_mem_o       <= 12'b0;
      csr_rd_value_mem_o   <= 32'b0;
      ebreak_trap_mem_o    <= 1'b0;
      ecall_trap_mem_o     <= 1'b0;
      pc_mem_o             <= 32'hDEADC0DE;
      sret_trap_mem_o      <= 1'b0;
      itlb_miss_mem_o      <= 1'b0;
      itlb_wr_en_mem_o     <= 1'b0;
      dtlb_wr_en_mem_o     <= 1'b0;
      rs1_mem_o            <= '1;
      rs2_mem_o            <= '1;
      load_page_fault_mem_o  <= 1'b0;
      store_page_fault_mem_o <= 1'b0;
      alu_result_mem_o       <= 32'b0;
      rob_tag_mem_o          <= '1;
    end
  else //if(!mem_stage_stall)
    begin
      load_value_mem_o       <= loaded_data       ;
      rd_label_mem_o         <= rd_label_mem_i    ;
      reg_write_en_mem_o     <= reg_write_en_mem_i;
      wb_sel_mem_o           <= wb_sel_mem_i      ;
      is_load_mem_o          <= is_load_mem_i     ;
      rd_value_mem_ro        <= rd_value_mem_wo   ;
      fetched_instruction_mem_o <= fetched_instruction_mem_i;
      csr_wr_en_mem_o        <= csr_wr_en_mem_i;
      csr_addr_mem_o         <= csr_addr_mem_i;
      csr_rd_value_mem_o     <= csr_rd_value_mem_i;
      ebreak_trap_mem_o      <= ebreak_trap_mem_i;
      ecall_trap_mem_o       <= ecall_trap_mem_i;
      pc_mem_o               <= pc_mem_i;
      sret_trap_mem_o        <= sret_trap_mem_i;
      itlb_miss_mem_o        <= itlb_miss_mem_i;
      itlb_wr_en_mem_o       <= itlb_wr_en_mem_i;
      dtlb_wr_en_mem_o       <= dtlb_wr_en_mem_i;
      rs1_mem_o              <= rs1_mem_i;
      rs2_mem_o              <= latest_rs2_value_mem_i;
      load_page_fault_mem_o  <= load_page_fault;
      store_page_fault_mem_o <= store_page_fault;
      alu_result_mem_o       <= alu_result_mem_i;
      rob_tag_mem_o          <= rob_tag_mem_i;
    end
  end

  wire [8*RISCV_DISASM_STRLEN-1:0] disasm_str = riscv_disasm(fetched_instruction_mem_i, pc_mem_i);
`ifdef CORE_VERBOSITY
  `define L1_DATA_CACHE_PATH l1_data_cache_u
  function void mem_trace_log(int file, int mem_dump_file,int cycle);
    $fwrite(file,"\n***********Memory Stage****************:");
    $fwrite(file,"\nTime: %1t, Instruction: %0s, Program Counter: 0x%8h, Instruction(x): 0x%8h", $time, disasm_str,pc_mem_i,fetched_instruction_mem_i);
    // if(`CORE_VERBOSITY >= 200)begin
    //   mem_op_trace(file);
    //   // csr_u.csr_trace_log(file);
    // end
    // if(`CORE_VERBOSITY >= 400)begin
    //   data_mem_subsystem_u.data_mem_subsystem_trace_log(file);
    //   dtlb_u.dtlb_trace_log(file);
    // end
    // `ifdef MEM_DUMP
    // if(cycle == 30000 || cycle == 1) begin
    //   data_mem_subsystem_u.DATA_RAM_u.memory_dump(mem_dump_file,cycle);  
    // end
    // `endif
  endfunction

  function void mem_op_trace(int file);
    $fwrite(file,"\nTime: %1t, address_i: 0x%8h, write_data_i: 0x%8h, is_load_instr: %b, is_store_instr: %b, funct3_i: %b, read_data_o: 0x%8h",$time,alu_result_mem_i,latest_rs2_value_mem_i,is_load_mem_i,is_store_mem_i,funct3_mem_i,data_read_from_mem);
  endfunction
`endif

endmodule
