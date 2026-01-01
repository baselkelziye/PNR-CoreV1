`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/13/2024 07:57:26 AM
// Design Name: 
// Module Name: instruction_execution
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


module instruction_execution(
  input clk_i, rst_i,

  //Inputs from Instruction Decode Stage
  input [31:0] rs1_data_ex_i, rs2_data_ex_i,
  input [4:0] rd_label_ex_i, rs1_label_ex_i, rs2_label_ex_i,
  input [31:0] imm_value_ex_i,
  input load_stall_ex_i, load_store_forward_sel_ex_i,
  input reg_write_en_ex_i,
  input [1:0] rs1_pc_imm_sel_ex_i, rs2_imm_csr_sel_ex_i,
  input is_branch_instr_ex_i, is_store_instr_ex_i, is_load_instr_ex_i,
  input [1:0] wb_sel_ex_i,
  input [3:0] alu_op_ex_i,
  input [31:0] pc_ex_i,
  input [2:0] funct3_ex_i,
  input unconditional_branch_ex_i,
  input [31:0] btb_predicted_pc_ex_i,
  input branch_is_taken_prediction_ex_i,
  input [31:0] fetched_instruction_ex_i,
  input ex_unit_sel_ex_i,
  input [7:0] sb_id_ex_i,
  //Trap & CSR Signals
  input csr_wr_en_ex_i,
  input [11:0] csr_addr_ex_i,
  input [31:0] csr_rd_value_ex_i,
  output reg [31:0] csr_rd_value_ex_o,
  input wire ecall_trap_ex_i, //DETE
  input wire ebreak_trap_ex_i, // DELETE
  output reg ecall_trap_ex_o, //DELETE
  output reg ebreak_trap_ex_o, //DELETE
  input wire sret_trap_ex_i, //DELETE
  output reg sret_trap_ex_o, //DELETE
  output reg csr_wr_en_ex_o, //DELETE
  output reg [31:0] imm_value_ex_o,
  output reg [31:0] rs1_value_ex_o,
  output reg [11:0] csr_addr_ex_o, //DELETE
  input wire trap_en_ex_i,
  input itlb_miss_ex_i,
  output reg itlb_miss_ex_o, //DELETE
  input itlb_wr_en_ex_i,
  input dtlb_wr_en_ex_i,
  output reg itlb_wr_en_ex_o, //DELETE
  output reg dtlb_wr_en_ex_o, //DELETE
  //Inputs to Decode Stage
  output wire [31:0] ex_stage_result_o,
  output wire mdu_stall_ex_o,

  //Outputs to Memory Stage
  output reg [31:0] alu_result_ex_o,
  output reg load_store_forward_sel_ex_o,
  output reg  reg_write_en_ex_o,
  output reg  is_load_instr_ex_o,
  output reg  is_store_instr_ex_o,
  output reg [4:0] rd_label_ex_o,
  output reg [1:0] wb_sel_ex_o,
  output reg [31:0] pc_ex_o,
  output reg [2:0] funct3_ex_o,
  output reg [31:0] latest_rs2_value_ex_o,
  output reg [31:0] fetched_instruction_ex_o,
  output reg [7:0] sb_id_ex_o,
  //Traps and CSR inputs
  //ROB
  input [3:0] rob_tag_ex_i,
  output reg [3:0] rob_tag_ex_o,
  input instr_valid_ex_i,
  output reg instr_valid_ex_o,
  //ROB commit interface
  output rob_commit_alu_done_ex_o,
  output [3:0] rob_commit_tag_ex_o,
  output [31:0] rob_commit_data_ex_o,
  output rob_commit_exception_ex_o,
  output [31:0] rob_commit_scause_ex_o,
  output [31:0] rob_commit_stval_ex_o,
  output rob_commit_branch_ex_o,
  output rob_commit_sret_ex_o,
  output [11:0] rob_commit_csr_addr_ex_o,
  output [31:0] rob_commit_branch_address_ex_o,
  output [31:0] rob_commit_rs1_ex_o,
  output [31:0] rob_commit_rs2_ex_o,
  output rob_commit_csr_wr_en_ex_o,
  output rob_commit_itlb_wr_en_ex_o,
  output rob_commit_dtlb_wr_en_ex_o,
  input rob_arbiter_stall_ex_i,
  //ROB MDU COMMIT
  output rob_commit_mdu_done_ex_o,
  output [3:0] rob_commit_mdu_tag_ex_o,
  output [31:0] rob_commit_mdu_result_o,
  input rob_arbiter_stall_mdu_ex_i,
  // input rob_exception_ex_i,
  // input rob_sret_ex_i,
  // input rob_flush_ex_i,
  //Inputs From Memory Stage
  input reg_write_en_mem_i,
  input [4:0] rd_label_mem_i,
  input [31:0] alu_result_mem_i,
  input [31:0] rd_value_mem_i,
  input [31:0] rd_value_wb_i,


  //Inputs From WriteBack Stage
  input reg_write_en_wb_i,
  input [4:0] rd_label_wb_i,

  
  //Multi-Usage output
  output wire branching_ex_o,
  output wire [31:0] branch_address_ex_o,
  output wire increment_counter_ex_o,
  output wire decrement_counter_ex_o,
  output wire update_btb_address_ex_o,

  input periheral_stall_ex_i,
  input mem_stage_stall_i
    );

  //Branch Jump Unit
  wire branch_jump_unit_o;
  wire branch_is_taken; // The branch real result 
  wire wrong_prediction_NT_T; 
  //ALU Signals
  wire [31:0] alu_result;
  wire [31:0] alu1_input, alu2_input;
  
  //MDU Signals
  wire [31:0] mdu_result;
  wire ex_stage_stall, ex_stage_flush;
  wire mdu_busy, mdu_done;

  //ROB signals for Validation of ROB entry
  wire alu_stage_done; //If the operation is ALU, and its done.

  assign ex_stage_stall = (periheral_stall_ex_i | mem_stage_stall_i) & ~trap_en_ex_i;
  assign ex_stage_flush = mdu_busy | trap_en_ex_i | rob_arbiter_stall_ex_i; //If mdu has stall, then ex_would have? Write assertioN?
  // assign branching
  assign branch_is_taken = (branch_jump_unit_o & is_branch_instr_ex_i) | unconditional_branch_ex_i;
  assign wrong_prediction_NT_T = branch_is_taken & ~branch_is_taken_prediction_ex_i;// we guessed NT but it is T
  assign branching_ex_o = branch_is_taken ^ branch_is_taken_prediction_ex_i; // We have branching because the branch status differens from the prediction
  assign update_btb_address_ex_o = branching_ex_o & wrong_prediction_NT_T; //If we branch from Not taken, to Taken. We need to update BTB (This can write same value to same address mutliple time no problem )
  //If we Guess NT and we Take we need to branch to calculated address
  //If we Guess T and we didn't take we need to branch to PC + 4
  assign branch_address_ex_o = (wrong_prediction_NT_T) ? alu_result : pc_ex_i + 32'h4;

  assign increment_counter_ex_o = (is_branch_instr_ex_i & branch_is_taken);
  assign decrement_counter_ex_o = (is_branch_instr_ex_i & ~branch_is_taken);

  //If instruction is valid, and its not store, load and not Multiplication. then its ALU
  //If instruction is ecall,ebreak or itlb miss exception, Also Commit trap!
  assign alu_stage_done = ((instr_valid_ex_i & ~is_load_instr_ex_i & ~is_store_instr_ex_i & ~ex_unit_sel_ex_i)
                          || (ecall_trap_ex_i || ebreak_trap_ex_i || sret_trap_ex_i || itlb_miss_ex_i)) && ~(trap_en_ex_i) ;
  


  reg exception_raised_ex;
  reg [31:0] scause_ex, stval_ex;

  always @(*) begin
    exception_raised_ex = 1'b0 ;
    scause_ex           = 32'b0;
    stval_ex            = 32'b0;
    if(ebreak_trap_ex_i) begin
        exception_raised_ex = 1'b1;
        scause_ex = {1'b0, 31'd3}; //Breakpoint Has Trap Code = 3
        //STVAL not important
    end else if(ecall_trap_ex_i) begin
        exception_raised_ex = 1'b1;
        scause_ex = {1'b0, 31'd8}; //ecall from UMODE has cause 8 
    end else if(itlb_miss_ex_i) begin
        exception_raised_ex = 1'b1;
        scause_ex = {1'b0, 31'd12}; //instruction page fault
        stval_ex = pc_ex_i;
    end 
  end

  assign rob_commit_alu_done_ex_o = alu_stage_done;
  assign rob_commit_tag_ex_o = rob_tag_ex_i;
  assign rob_commit_data_ex_o = ex_stage_result_o;

  assign rob_commit_exception_ex_o = exception_raised_ex;
  assign rob_commit_scause_ex_o = scause_ex;
  assign rob_commit_stval_ex_o = stval_ex;
  assign rob_commit_sret_ex_o = sret_trap_ex_i;

  assign rob_commit_branch_ex_o = branching_ex_o;
  assign rob_commit_branch_address_ex_o = branch_address_ex_o;

  assign rob_commit_csr_addr_ex_o = csr_addr_ex_i;
  assign rob_commit_csr_wr_en_ex_o = csr_wr_en_ex_i;

  assign rob_commit_rs1_ex_o = alu1_input;
  assign rob_commit_rs2_ex_o = alu2_input;

  assign rob_commit_itlb_wr_en_ex_o = itlb_wr_en_ex_i;
  assign rob_commit_dtlb_wr_en_ex_o = dtlb_wr_en_ex_i;
  branch_jump branch_jump_u(
      .in1_i            (   rs1_data_ex_i       ),
      .in2_i            (   rs2_data_ex_i       ),
      .funct3_i         (   funct3_ex_i         ),
      .branch_valid_o   (   branch_jump_unit_o  )
  );

  mux_4x1 #(
      .DATA_WIDTH(32))
  alu1_selector(
      .in0_i   (   rs1_data_ex_i        ),
      .in1_i   (   pc_ex_i              ),
      .in2_i   (   imm_value_ex_i       ),
      .in3_i   (   32'hAD0BE            ),
      .sel_i   (   rs1_pc_imm_sel_ex_i  ),
      .out_o   (   alu1_input           )
  );

mux_4x1 #(
    .DATA_WIDTH(32)
) alu2_selector(
    .in0_i  (   rs2_data_ex_i         ),
    .in1_i  (   imm_value_ex_i        ),
    .in2_i  (   csr_rd_value_ex_i        ),
    .in3_i  (   32'hAD0BE             ),
    .sel_i  (   rs2_imm_csr_sel_ex_i  ),
    .out_o  (   alu2_input            )
);

ALU ALU_u(
    .alu1_i     (   alu1_input    ),
    .alu2_i     (   alu2_input    ),
    .alu_op_i   (   alu_op_ex_i   ),
    .result_o   (   alu_result    )
);

wire [3:0]  rob_commit_mdu_tag;
wire [31:0] rob_commit_mdu_pc;


assign rob_commit_mdu_done_ex_o = mdu_done;
assign rob_commit_mdu_tag_ex_o = rob_commit_mdu_tag;
assign rob_commit_mdu_result_o = mdu_result;

MDU MDU_u(
  .clk_i        ( clk_i             ),
  .rst_i        ( rst_i             ),
  .start_mdu_i  ( ex_unit_sel_ex_i & instr_valid_ex_i  ), //This indicates a M extension OP
  .mem_stall_i  ( mem_stage_stall_i ),
  .mdu_arbiter_stall_i(rob_arbiter_stall_mdu_ex_i),
  .i_rob_tag(rob_tag_ex_i),
  .i_pc(pc_ex_i),
  .o_mdu_tag(rob_commit_mdu_tag),
  .o_mdu_pc(rob_commit_mdu_pc), // Requiered?? 
  .MDU_op_i     ( funct3_ex_i       ),
  .MDU_op1_i    ( rs1_data_ex_i     ),
  .MDU_op2_i    ( rs2_data_ex_i     ),
  .MDU_result_o ( mdu_result        ),
  .mdu_busy_o   ( mdu_busy          ),
  .mdu_done_o   ( mdu_done          )
);

assign ex_stage_result_o = (ex_unit_sel_ex_i == 1'b1) ? mdu_result : alu_result;
assign mdu_stall_ex_o = mdu_busy;
always @(posedge clk_i, posedge rst_i) begin
  if(rst_i) begin
      alu_result_ex_o             <= 32'h0 ;
      load_store_forward_sel_ex_o <= 1'b0  ;
      reg_write_en_ex_o           <= 1'b0  ;
      is_load_instr_ex_o          <= 1'b0  ;
      rd_label_ex_o               <= 5'b0  ;
      wb_sel_ex_o                 <= 3'b0  ;
      pc_ex_o                     <= 32'b0 ;
      funct3_ex_o                 <= 3'b0  ;
      is_store_instr_ex_o         <= 1'b0  ;
      latest_rs2_value_ex_o       <= 32'h0 ;
      fetched_instruction_ex_o    <= 32'h13;
      sb_id_ex_o                  <= 8'b0  ;
      imm_value_ex_o              <= 32'b0 ;
      rs1_value_ex_o              <= 32'b0 ;
      csr_wr_en_ex_o              <= 1'b0  ;
      csr_addr_ex_o               <= 12'b0 ;
      csr_rd_value_ex_o           <= 32'b0 ;
      ebreak_trap_ex_o            <= 1'b0  ;
      ecall_trap_ex_o             <= 1'b0  ;
      sret_trap_ex_o              <= 1'b0  ;
      itlb_miss_ex_o              <= 1'b0  ;
      itlb_wr_en_ex_o             <= 1'b0  ;
      dtlb_wr_en_ex_o             <= 1'b0  ;
      rob_tag_ex_o                <= '1;
      instr_valid_ex_o            <= 1'b0;
  end else if(ex_stage_flush & !ex_stage_stall) begin 
      reg_write_en_ex_o           <= 1'b0   ;
      fetched_instruction_ex_o    <= 32'h13 ;
      sb_id_ex_o                  <= 8'b0   ;
      is_load_instr_ex_o          <= 1'b0   ;
      is_store_instr_ex_o         <= 1'b0   ;
      csr_wr_en_ex_o              <= 1'b0   ;
      ebreak_trap_ex_o            <= 1'b0   ;
      ecall_trap_ex_o             <= 1'b0   ;
      sret_trap_ex_o              <= 1'b0   ;
      itlb_miss_ex_o              <= 1'b0   ;
      itlb_wr_en_ex_o             <= 1'b0   ;
      dtlb_wr_en_ex_o             <= 1'b0   ;
      rob_tag_ex_o                <= '1;
      instr_valid_ex_o            <= 1'b0;
  end else if (!ex_stage_stall) begin
      alu_result_ex_o             <= ex_stage_result_o          ;
      load_store_forward_sel_ex_o <= load_store_forward_sel_ex_i;
      reg_write_en_ex_o           <= reg_write_en_ex_i          ;
      is_load_instr_ex_o          <= is_load_instr_ex_i         ;
      rd_label_ex_o               <= rd_label_ex_i              ;
      wb_sel_ex_o                 <= wb_sel_ex_i                ;
      pc_ex_o                     <= pc_ex_i                    ;
      funct3_ex_o                 <= funct3_ex_i                ;
      is_store_instr_ex_o         <= is_store_instr_ex_i        ;
      latest_rs2_value_ex_o       <= rs2_data_ex_i              ;
      fetched_instruction_ex_o    <= fetched_instruction_ex_i   ;
      sb_id_ex_o                  <= sb_id_ex_i                 ;
      imm_value_ex_o              <= imm_value_ex_i             ;
      rs1_value_ex_o              <= rs1_data_ex_i              ;
      csr_wr_en_ex_o              <= csr_wr_en_ex_i             ;
      csr_addr_ex_o               <= csr_addr_ex_i              ;
      csr_rd_value_ex_o           <= csr_rd_value_ex_i          ;
      ebreak_trap_ex_o            <= ebreak_trap_ex_i           ;
      ecall_trap_ex_o             <= ecall_trap_ex_i            ;
      sret_trap_ex_o              <= sret_trap_ex_i             ;
      itlb_miss_ex_o              <= itlb_miss_ex_i             ;
      itlb_wr_en_ex_o             <= itlb_wr_en_ex_i            ;
      dtlb_wr_en_ex_o             <= dtlb_wr_en_ex_i            ;
      rob_tag_ex_o                <= rob_tag_ex_i;
      instr_valid_ex_o            <= instr_valid_ex_i;
  end
end

wire [8*RISCV_DISASM_STRLEN-1:0] disasm_str = riscv_disasm(fetched_instruction_ex_i, pc_ex_i);
`ifdef CORE_VERBOSITY
  `define ALU_PATH ALU_u
  function void ex_trace_log(int file);
    $fwrite(file,"\n***********Execution Stage****************:");
    $fwrite(file,"\nTime: %1t, Instruction: %0s, Program Counter: 0x%8h, periheral_stall_ex_i: %b, mem_stage_stall_i: %b", $time, disasm_str,pc_ex_i,periheral_stall_ex_i,mem_stage_stall_i);
    mdu_op_trace(file);
    // if(`CORE_VERBOSITY >= 500 ) begin
    //   $fwrite(file, "\nTime: %1t, rs1_data_ex_i: 0x%h, pc_ex_i: 0x%h, imm_value_ex_i: 0x%h, rs1_pc_imm_sel: %b", $time,rs1_data_ex_i,pc_ex_i,imm_value_ex_i,rs1_pc_imm_sel_ex_i);
    //   $fwrite(file, "\nTime: %1t, rs2_data_ex_i: 0x%h, imm_value_ex_i: 0x%h, csr_rd_value_ex_i: 0x%h, rs2_imm_csr_sel_ex_i: %b", $time,rs2_data_ex_i,imm_value_ex_i,csr_rd_value_ex_i,rs2_imm_csr_sel_ex_i);
    //     alu_op_trace(file);
    //     // mdu_op_trace(file);
    //     branch_op_trace(file);
    // end
  endfunction

  function void alu_op_trace(int file);
  $fwrite(file, "\nTime: %1t ALU, alu1_input: 0x%8h, alu2_input: 0x%8h, alu_op_ex_i: %0b,  alu_result: 0x%8h",$time,alu1_input,alu2_input,alu_op_ex_i,alu_result);
  // ALU_PATH.alu_trace_log(file);
  endfunction

  function void mdu_op_trace(int file);
  MDU_u.mdu_trace_log(file);
  endfunction

  function void branch_op_trace(int file);
//   $fwrite(file, "\nBranching:");
  $fwrite(file, "\nTime: %1t Branching, branch_is_taken: %0b, wrong_prediction_NT_T: %0b, branching_ex_o: %0b, branch_address_ex_o: %0h ", $time, branch_is_taken, wrong_prediction_NT_T,branching_ex_o, branch_address_ex_o);
  
  endfunction
`endif


endmodule
