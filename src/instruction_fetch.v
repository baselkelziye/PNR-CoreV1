`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2024 10:26:49 AM
// Design Name: 
// Module Name: instruction_fetch
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


module instruction_fetch #(
  parameter I_WORDS_PER_LINE = 4,
  localparam INSTRUCTION_WIDTH = 32
)
(
  input clk_i, rst_i,
  
  output reg [31:0] fetched_instruction_if_o,
  output reg [31:0] pc_incremented_if_o,

  //Inputs From Decode Stage For load Hazard
  input wire load_stall_if_i,
  
  //Input From Execution Stage
  input wire branching_i, //When we branch we need to NOP the instructions in the PIPELINE
  input wire [31:0] branching_address_i,
  input wire [31:0] pc_ex_i, //This is the PC for the branch instruction in EX Stage
  input wire mdu_stall_ex_i,

  //Exception Inputs
  input wire [31:0] stvec_csr_i,
  input wire trap_en_if_i,
  input wire [1:0] current_execution_mode_if_i,
  input wire sret_trap_wb_i,
  input wire [31:0] trap_return_pc_i, //This is MEPC

  //Inputs For Branch Prediction.
  input wire is_branch_instr_ex_i,
  input wire decrement_counter_i, increment_counter_i, //we need to 0 the counter on reset
  input wire update_btb_address_i,
  //Outputs For Branch Prediction
  output reg [31:0] btb_predicted_pc_if_o,
  output reg branch_is_taken_prediction_if_o,

  //icache signals
  input wire icache_fill_done_if_i, //input from ram that fill request is done
  output wire icache_fill_req_if_o, //Request ICache Line
  output wire [29:0] icache_fill_rd_addr_if_o, //ICache Line Request Address
  input [INSTRUCTION_WIDTH-1:0] icache_fill_line_data_if_i[0:I_WORDS_PER_LINE-1], //ICache Line Data
  //icache <-> arbiter
  output icache_req_valid_if_o, //Request icache access from aribter
  input icache_req_ready_if_i, //Arbiter grants icache
  output icache_data_ready_if_o,

  //icache <-> RAM
  input icache_resp_valid_if_i,
  input ram_response_id_if_i,

  //itlb signals
  output reg itlb_miss_if_o,
  input itlb_wr_en_if_i, //Comes from WB
  input [31:0] rs1_if_i,
  input [31:0] rs2_if_i,

  //ROB signals
  output reg instr_valid_if_o, //Indicates its valid instruction and not a Bubble

  input wire periheral_stall_if_i,
  input wire mem_stage_stall_i
);
    `include "disassembler.v"
  reg [31:0] pc_next;
  wire [31:0] fetched_instruction, btb_predicted_pc;
  reg  [31:0] pc_reg;
  wire branch_is_taken_prediction;
  localparam [31:0] INSTR_NOP = 32'h00000013;
  
  wire if_stage_stall;
  wire if_flush;
  wire icache_stall;
  wire [31:0] physical_pc;


  assign if_stage_stall = (load_stall_if_i | periheral_stall_if_i | mem_stage_stall_i | mdu_stall_ex_i) & ~trap_en_if_i;
  assign if_flush = branching_i | trap_en_if_i | sret_trap_wb_i;


  always @(posedge clk_i, posedge rst_i)
  begin
    if(rst_i) 
      pc_reg <=  32'h80000000;
    else if((!if_stage_stall & !icache_stall) || branching_i || trap_en_if_i || sret_trap_wb_i)
      pc_reg <= pc_next;
  end


  assign icache_fill_rd_addr_if_o = physical_pc[31:2];
    
	always @*
  begin
    if(trap_en_if_i) begin
      pc_next = stvec_csr_i;
    end else if(sret_trap_wb_i) begin
      pc_next = trap_return_pc_i;
    end else if(branching_i) begin      
      // If we have branch, Then Next shall be the calculated New address adn means we predicted wrong.
	    pc_next = branching_address_i;
		end else
      begin
			  if(branch_is_taken_prediction)
			    pc_next = btb_predicted_pc;
			  else
			    pc_next = pc_reg + 32'd4;
		  end
	end
//    assign pc_next = (branch_is_taken_prediction) ? btb_predicted_pc : pc_reg + 32'd4;
  wire icache_fill_req;
  wire itlb_miss;
  wire kill_icache;
  assign kill_icache = branching_i | trap_en_if_i | sret_trap_wb_i;
  imem_subsystem imem_subsystem_u(
    .clk_i                    (       clk_i                 ),
    .rst_i                    (       rst_i                 ),
    .icache_pc_i              (       pc_reg                ),
    .icache_fill_done_i       (      icache_fill_done_if_i  ),
    .icache_fill_line_data_i  (   icache_fill_line_data_if_i),
    .icache_fill_stall_o      (       icache_stall          ),
    .icache_fill_req_o        (       icache_fill_req_if_o  ),
    .icache_fetched_instr_o   (       fetched_instruction   ),
    //Arbiter-icache interface
    .icache_req_ready_i       (       icache_req_ready_if_i ), //arbiter grants access to icache
    .icache_req_valid_o       (       icache_req_valid_if_o ),
    .icache_data_ready_o      (       icache_data_ready_if_o),
    //RAM-icache interface
    .icache_resp_valid_i      (     icache_resp_valid_if_i  ),
    .ram_response_id_i        (     ram_response_id_if_i    ),
    .branch_ex_i              (     kill_icache             ),
    .itlb_miss_o              (     itlb_miss               ),
    .itlb_wr_en_i             (     itlb_wr_en_if_i         ),
    .rs1_i                    (     rs1_if_i                ),
    .rs2_i                    (     rs2_if_i                ),
    .physical_pc_o            (     physical_pc             ),
    .execution_mode_i         (   current_execution_mode_if_i)

  );

  // instr_cache instr_cache_u(
  //   .pc_i     (   pc_reg             ),
  //   .instr_o  (   fetched_instruction)
  // );

  branch_predictor #(.N(4))
  branch_predictor_u (
    .clk_i                (   clk_i                               ),
    .rst_i                (   rst_i                               ),
    .pc_i                 (   pc_reg                              ),
    .pc_ex_i              (   pc_ex_i                             ),
    .btb_address_value_i  (   branching_address_i                 ),
    .update_btb_address_i (   update_btb_address_i                ),
    .btb_fetched_address_o(   btb_predicted_pc                    ),
    .increment_counter    (   increment_counter_i                 ),
    .decrement_counter    (   decrement_counter_i                 ),
    .branch_is_taken      (   branch_is_taken_prediction          )
    );

  always @(posedge clk_i, posedge rst_i)
  begin
    if(rst_i)
      begin
        fetched_instruction_if_o        <= 32'h13;
        pc_incremented_if_o             <= 32'h80000000;
        branch_is_taken_prediction_if_o <= 1'b0;
        btb_predicted_pc_if_o           <= 32'h0;
        itlb_miss_if_o                  <= 1'b0;
        instr_valid_if_o                <= 1'b0;
      end
    else if((if_flush  | icache_stall) & !if_stage_stall) // If later Pipe is stalling, we shouldn't NOP otherwise we will lose the instruction in the next stage!
      begin //Flush Sadece Branchte olur simdilik
        fetched_instruction_if_o        <= INSTR_NOP;
        pc_incremented_if_o             <= 32'hDEADC0DE;
        branch_is_taken_prediction_if_o <= 1'b0;
        btb_predicted_pc_if_o           <= 32'h0;
        fetched_instruction_if_o        <= 32'h13;
        itlb_miss_if_o                  <= 1'b0;
        instr_valid_if_o                <= 1'b0;
      end
    else if(!if_stage_stall & !icache_stall)
      begin
        fetched_instruction_if_o        <= (fetched_instruction == 32'h00130001 | fetched_instruction == 32'h00130000 | fetched_instruction == 32'h00010000 | fetched_instruction == 32'h0) ? 32'h13 : fetched_instruction;
        pc_incremented_if_o             <=  pc_reg;
        branch_is_taken_prediction_if_o <= branch_is_taken_prediction;
        btb_predicted_pc_if_o           <= btb_predicted_pc;
        itlb_miss_if_o                  <= itlb_miss;
        instr_valid_if_o                <= 1'b1; //Check this signal when itlb goes high
      end //If There is stall, Latch the last values (No Change)
  end

  wire [8*RISCV_DISASM_STRLEN-1:0] disasm_str = riscv_disasm(fetched_instruction, pc_reg);
  `ifdef CORE_VERBOSITY
    function void if_trace_log(int file);
      $fwrite(file,"\n***********Instruction Fetch Stage****************:");
      $fwrite(file,"\nTime %1t, Instruction: %0s, Program Counter: 0x%8h, load_stall_if_i: %b, periheral_stall_if_i: %b, mem_stage_stall_i: %b ", $time, disasm_str,pc_reg,load_stall_if_i,periheral_stall_if_i,mem_stage_stall_i);
      if(`CORE_VERBOSITY >= 600) begin
        // branch_predictor_u.branch_predictor_trace_log(file);
        // branch_predictor_u.BTB_trace_log(file);
        // imem_subsystem_u.imem_subsystem_trace_log(file);
        // imem_subsystem_u.l1_icache_array_u.l1_icache_array_trace_log(file);
        // imem_subsystem_u.l1_icache_controller_u.icache_controller_trace_log(file);
      end
    endfunction
  `endif
    
endmodule
