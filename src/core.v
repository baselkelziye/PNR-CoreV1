`timescale 1ns / 1ps
/*
NOTES:
When To Commit DTLB? Since its in Supervisor,  we are sure no exceptions will happen? Can i just commit directly?
*/


/*
Assertions to be Added:

1- Branch Predictor Should Never Predict Taken if the Instruction is not a Branch (Add mini-decoder)
2- In WB Stage, An Exception Shouldn't fire if the Instruction is CSRRW (SPEC Take value from TRAP or Decode???)
*/

/*
STATUS:
ROB captures load value correctly but then overwrites it again, When drain and Load are in mem!

Need to implement Multiplication!
reset memory in memory model is not sufficient hence tests are failing
*/

/*
Perfomance Bottlenecks
1- itlb and dtlb can be written to Rob in ID stage, now its from EX
2- Same as above for: ecall, sret, ebreak
3- now ROB saves rs1  (VA) and rs2 (Content) for tlb writes, instead VA can be read from STVAL implicitly!
4- matrix multiplication code is figihting for cache lines can be improved!!!
  

*/ 

module core(
    input clk_i, rst_i
);

localparam I_ENTRIES = 32;
localparam I_WORDS_PER_LINE = 4;
localparam INSTRUCTION_WIDTH = 32;
localparam D_WORDS_PER_LINE = 4;
localparam DATA_WIDTH =32 ;
//Instruction Fetch Stage Variables
wire [31:0] pc_incremented_if_o;
wire [31:0] fetched_instruction_if_o;
wire [31:0] btb_predicted_pc_if_o;
wire branch_is_taken_prediction_if_o;
wire itlb_miss_if_o;
//--------------------------------------------


//Instruction Decode Stage Variable Declarations
wire [31:0] rs1_data_id_o, rs2_data_id_o;
wire [4:0] rd_label_id_o, rs1_label_id_o, rs2_label_id_o;
wire [31:0] imm_value_id_o;
wire load_stall_id_o, load_store_forward_sel_id_o;
wire reg_write_en_id_o;
wire [1:0] rs1_pc_imm_sel_id_o, rs2_imm_csr_sel_id_o;
wire is_branch_instr_id_o, is_store_instr_id_o, is_load_instr_id_o;
wire [1:0] wb_sel_id_o;
wire [3:0] alu_op_id_o;
wire [31:0] pc_id_o,fetched_instruction_id_o;
wire [2:0] funct3_id_o;
wire unconditional_branch_id_o;
wire [31:0] btb_predicted_pc_id_o;
wire branch_is_taken_prediction_id_o;
wire ex_unit_sel_id_o;
wire [7:0] sb_id_o;
wire [11:0] csr_addr_id_o;
wire itlb_miss_id_o;
wire itlb_wr_en_id_o,dtlb_wr_en_id_o;
//CSR Signals
wire csr_wr_en_id_o;
wire csr_wr_en_mem_o;
wire [31:0] csr_rd_value_id_o;
wire ebreak_trap_id_o, ecall_trap_id_o;
wire sret_trap_id_o;
wire [31:0] stvec_id_o;
wire [31:0] sepc_id_o;
//--------------------------------------------


//Instruction Execution Stage Variable Declarations
wire [31:0] alu_result_ex_o;
wire load_store_forward_sel_ex_o;
wire reg_write_en_ex_o;
wire is_load_instr_ex_o;
wire is_store_instr_ex_o;
wire [4:0] rd_label_ex_o;
wire [1:0] wb_sel_ex_o;
wire [31:0] pc_ex_o;
wire [31:0] latest_rs2_value_ex_o;
wire [2:0] funct3_ex_o;
wire branching_ex_o;
wire [31:0] branch_address_ex_o;
wire increment_counter_ex_o, decrement_counter_ex_o;
wire [31:0] fetched_instruction_ex_o;
wire [31:0] rd_value_ex_o;
wire [7:0] sb_id_ex_o;
wire mdu_stall_ex;
wire [31:0] imm_value_ex_o, rs1_value_ex_o;
wire csr_wr_en_ex_o;
wire [11:0] csr_addr_ex_o;
wire [31:0] csr_rd_value_ex_o;
wire ecall_trap_ex_o, ebreak_trap_ex_o;
wire sret_trap_ex_o;
wire update_btb_address_ex_o;
wire itlb_miss_ex_o;
wire itlb_wr_en_ex_o,dtlb_wr_en_ex_o;
//--------------------------------------------

//Instruction Memory Stage Variable Declarations
wire [31:0] alu_result_mem_o;
wire [31:0] load_value_mem_o;
wire [31:0] pc_mem_o;
wire [4:0] rd_label_mem_o;
wire reg_write_en_mem_o;
wire [1:0] wb_sel_mem_o;
wire is_load_mem_o;
wire [31:0] rd_value_mem_wo;
wire [31:0] rd_value_mem_ro;
wire [11:0] csr_addr_mem_o;
wire [31:0] csr_rd_value_mem_o;
wire ecall_trap_mem_o, ebreak_trap_mem_o;
wire sret_trap_mem_o;
wire itlb_miss_mem_o;
wire itlb_wr_en_mem_o,dtlb_wr_en_mem_o;
wire [31:0] rs1_mem_o, rs2_mem_o;
//Wishbone + Peripherals
wire peripheral_stall_mem_o;
wire mem_stage_stall;
//--------------------------------------------

//WriteBack Stage Variable Declarations
wire [31:0] rd_value_wb_mem_o;
wire reg_write_en_wb_o;
wire [31:0] alu_result_wb_o, load_data_wb_o, pc_wb_o;
wire [31:0] fetched_instruction_wb;
wire load_page_fault_mem_o, store_page_fault_mem_o;
// wire [31:0] pc_mem_o;
reg exception_raised;
reg [31:0] scause;
reg [31:0] stval;


reg [1:0] current_execution_mode;

//Icache <--> RAM 
wire [INSTRUCTION_WIDTH-1:0] icache_line_fill_data[0:I_WORDS_PER_LINE-1];
wire [DATA_WIDTH-1:0] dcache_line_fill_data_o[0:D_WORDS_PER_LINE-1];
wire [DATA_WIDTH-1:0] dcache_line_evict_mem_o[0:D_WORDS_PER_LINE-1];
wire [INSTRUCTION_WIDTH-1-2:0] icache_fill_rd_addr;

//icache <-> arbiter
wire icache_req_ready_o;

//Icache and Dcache Arbiter
wire arb_req_ready_o;
wire arb_req_valid_o;
wire arb_rd_wr_o;
wire arb_req_id_o;
wire cache_ready_o;
//MEMORY BLOCK
wire ram_data_valid_o;
wire [29:0] arb_address_o;
// wire [29:0] dcache_addr_req;
wire dcache_resp_valid_o, icache_resp_valid_o;
//On reset go to U_MODE, Isa goes to M Mode later to be modified
//Now, I only Do SRET to go back to u-mode, Later need to involve sstatus, mstatus.
always @(posedge clk_i, posedge rst_i) begin
  if(rst_i) begin
    current_execution_mode <= `U_MODE;
  end else begin
    if(rob_exception) begin
      //If Trap Happens go to higher privilege
      //Now i only go from U to S mode
      case (current_execution_mode)
        `U_MODE: current_execution_mode <= `S_MODE; 
        `S_MODE: current_execution_mode <= `M_MODE;
        `M_MODE: current_execution_mode <= `M_MODE;
        default: current_execution_mode <= `U_MODE;
      endcase
    end else if(rob_sret) begin // Return to U-MODE
          current_execution_mode <= `U_MODE;
    end
  end
end

wire icache_fill_req_if_o, icache_fill_done_if_i;
wire icache_req_valid_if_o,icache_data_ready_if_o;
wire dcache_req_valid_mem_o, dcache_req_valid_mem_i;
wire [29:0] dcache_address_mem_o;
wire dcache_rd_wr_mem_o,dcache_req_ready_o,dcache_data_ready_mem_o;

//ROB
wire instr_valid_if_o;
wire o_rob_full,alloc_en_id_o;
wire [4:0] alloc_rd_id_o;
wire alloc_wr_en_id_o;
wire alloc_is_store_id_o;
wire [3:0] o_alloc_tag;
wire [3:0] rs1_rob_tag_id_o, rs2_rob_tag_id_o;
wire [31:0] rs1_rob_value_id_i, rs2_rob_value_id_i;
wire [3:0] rob_tag_id_o, rob_tag_ex_o, rob_tag_mem_o;
wire instr_valid_id_o, instr_valid_ex_o, instr_valid_mem_o;
wire rob_commit_alu_done_ex_o, mem_done_ex_o;
wire [3:0] rob_commit_tag_ex_o, rob_commit_tag_mem_o;
wire [31:0] rob_commit_data_ex_o, rob_commit_data_mem_o;
wire rob_commit_exception_ex_o;
wire [31:0] rob_commit_scause_ex_o,rob_commit_stval_ex_o;
wire [31:0] rob_commit_branch_address_ex_o;
wire rob_commit_branch_ex_o;
wire rob_commit_sret_ex_o;
wire [11:0] rob_commit_csr_addr_ex_o;
wire rob_commit_mem_done_mem_o,rob_commit_exception_mem_o;
wire [31:0] rob_commit_scause_mem_o,rob_commit_stval_mem_o;
wire rob_commit_csr_wr_en_ex_o;
wire [31:0] rob_commit_rs1_ex_o,rob_commit_rs2_ex_o;
wire rob_commit_itlb_wr_en_ex_o, rob_commit_dtlb_wr_en_ex_o;
wire rob_commit_mdu_done_ex_o;
wire [3:0] rob_commit_mdu_tag_ex_o;
wire [31:0] rob_commit_mdu_result_o;
wire rob_commit_unconditional_branch_ex_o;
// wire [31:0] rob_commit_data_mem_o;
instruction_fetch if_u
(
  .clk_i                          (   clk_i                             ),
  .rst_i                          (   rst_i                             ),
  .fetched_instruction_if_o       (   fetched_instruction_if_o          ),
  .pc_incremented_if_o            (   pc_incremented_if_o               ),
  //Inputs From  Instruction Decode Stage For Load Hazard
  .load_stall_if_i                (   load_stall_id_o                   ),
  //Inputs From Execution Stage For Branching,
  .branching_i                    (   rob_flush                         ), //Branch Occurs from ROB
  .branching_address_i            (   rob_flush_pc                      ), // Branching Address is also from ROB
  //Inputs From Execution Stage For Branch Prediction
  .is_branch_instr_ex_i           (   is_branch_instr_id_o              ), // The output reg of id =  is equal to ex_wire
  .decrement_counter_i            (   decrement_counter_ex_o            ),
  .increment_counter_i            (   increment_counter_ex_o            ),
  .update_btb_address_i           (   update_btb_address_ex_o           ),
  .btb_branch_address_i           (   branch_address_ex_o               ), //BP is updated in EX, not when Branch is committed!!
  .pc_ex_i                        (   pc_id_o                           ),
  .mdu_stall_ex_i                 (   mdu_stall_ex                      ),
  .rob_arbiter_stall_if_i(alu_arbiter_stall),
  //Trap Signals
  .stvec_csr_i                    (   stvec_id_o                       ),
  .trap_en_if_i                   (   rob_exception                    ),
  .sret_trap_wb_i                 (   rob_sret                   ),
  .trap_return_pc_i               (   sepc_id_o                         ),
  .current_execution_mode_if_i    (   current_execution_mode            ),
  //Outputs For Branch Prediction
  .btb_predicted_pc_if_o          (   btb_predicted_pc_if_o             ),
  .branch_is_taken_prediction_if_o(   branch_is_taken_prediction_if_o   ),
  //icache signals
  .icache_fill_done_if_i          (   icache_fill_done_if_i             ),
  .icache_fill_req_if_o           (   icache_fill_req_if_o              ),
  .icache_fill_rd_addr_if_o       (   icache_fill_rd_addr               ),
  .icache_fill_line_data_if_i     (   icache_line_fill_data             ),
  .icache_resp_valid_if_i         (   icache_resp_valid_o               ), //Ram finished transaction, ID is used to seperate icache and dcache requets
  .ram_response_id_if_i           (   arb_req_id_o                      ), //This is the arbited response
  //icache <-> Arbiter
  .icache_req_valid_if_o          (icache_req_valid_if_o),
  .icache_req_ready_if_i          (icache_req_ready_o),
  .icache_data_ready_if_o         (icache_data_ready_if_o),
  .periheral_stall_if_i           (   peripheral_stall_mem_o            ),
  .mem_stage_stall_i              (   mem_stage_stall                   ),
  //itlb
  .itlb_miss_if_o                 ( itlb_miss_if_o              ),
  .itlb_wr_en_if_i                ( rob_commit_itlb_wr_en            ),
  .rs1_if_i                       ( rob_commit_rs1                   ),
  .rs2_if_i                       ( rob_commit_rs2                   ),
  //ROB
  .instr_valid_if_o               (instr_valid_if_o)
);

instruction_decode id_u
(
  .clk_i                          (   clk_i                             ),
  .rst_i                          (   rst_i                             ),
  //Instruction Fetch Inputs
  .fetched_instruction_id_i       (   fetched_instruction_if_o          ),
  .pc_id_i                        (   pc_incremented_if_o               ),
  //Register Related Outputs
  .rs1_data_id_o                  (   rs1_data_id_o                     ),
  .rs2_data_id_o                  (   rs2_data_id_o                     ),
  .rd_label_id_o                  (   rd_label_id_o                     ),
  .rs1_label_id_o                 (   rs1_label_id_o                    ),
  .rs2_label_id_o                 (   rs2_label_id_o                    ),
  //Immediate Value
  .imm_value_id_o                 (   imm_value_id_o                    ),
  //Hazard Detection Unit
  .load_stall_id_o                (   load_stall_id_o                   ),
  .load_store_forward_sel_id_o    (   load_store_forward_sel_id_o       ),
  //Control Unit
  .reg_write_en_id_o              (   reg_write_en_id_o                 ),
  .rs1_pc_imm_sel_id_o            (   rs1_pc_imm_sel_id_o               ),
  .rs2_imm_csr_sel_id_o           (   rs2_imm_csr_sel_id_o              ),
  .is_branch_instr_id_o           (   is_branch_instr_id_o              ),
  .is_store_instr_id_o            (   is_store_instr_id_o               ),
  .is_load_instr_id_o             (   is_load_instr_id_o                ),
  .wb_sel_id_o                    (   wb_sel_id_o                       ),
  .alu_op_id_o                    (   alu_op_id_o                       ),
  .unconditional_branch_id_o      (   unconditional_branch_id_o         ),
  .ex_unit_sel_o                  (   ex_unit_sel_id_o                  ),
  .trap_en_id_i                   (   rob_exception                     ),
  .itlb_wr_en_id_o                (   itlb_wr_en_id_o                   ),
  .dtlb_wr_en_id_o                (   dtlb_wr_en_id_o                   ),
  //Program Counter
  .pc_id_o                        (   pc_id_o                           ),
  .fetched_instruction_id_o       (   fetched_instruction_id_o          ),
  .funct3_id_o                    (   funct3_id_o                       ),
  //Branch prediction,
  .btb_predicted_pc_id_i          (   btb_predicted_pc_if_o             ),
  .branch_is_taken_prediction_id_i(   branch_is_taken_prediction_if_o   ),
  .btb_predicted_pc_id_o          (   btb_predicted_pc_id_o             ),
  .branch_is_taken_prediction_id_o(   branch_is_taken_prediction_id_o   ),
  //Outputs to ROB and SB
  .sb_id_o                        (   sb_id_o                           ),
  //Inputs from Exeuction Stage
  .is_load_instr_ex_i             (   is_load_instr_id_o                ),
  .reg_write_en_ex_i              (   reg_write_en_id_o                 ),
  .rd_label_ex_i                  (   rd_label_id_o                     ),
  .rd_value_ex_i                  (   rd_value_ex_o                     ),
  .mdu_stall_ex_i                 (   mdu_stall_ex                      ),
  .rob_arbiter_stall_id_i(alu_arbiter_stall),
  //Inputs From Memory Stages
  .reg_write_en_mem_i             (   reg_write_en_ex_o                 ),
  .rd_label_mem_i                 (   rd_label_ex_o                     ),
  .rd_value_mem_i                 (   alu_result_ex_o                   ),
  .is_load_instr_mem_i            (   is_load_instr_ex_o                ),
  //Inputs From WriteBack Stage
  .reg_write_en_wb_i              (   reg_write_en_mem_o                ),
  .rd_label_wb_i                  (   rd_label_mem_o                    ),
  .rd_value_wb_i                  (   rd_value_mem_ro                   ),
  //Inputs To CSR/Trap Logic
  .csr_wr_en_wb_i                 (   rob_commit_csr_wr_en              ),
  .csr_wr_addr_wb_i               (   rob_commit_csr_addr               ),
  .csr_rd_value_wb_i              (   csr_rd_value_mem_o                ),
  .csr_wr_en_o                    (   csr_wr_en_id_o                    ),
  .csr_addr_id_o                  (   csr_addr_id_o                     ),
  .csr_rd_value_id_o              (   csr_rd_value_id_o                 ),
  .ecall_trap_id_o                (   ecall_trap_id_o                   ),
  .ebreak_trap_id_o               (   ebreak_trap_id_o                  ),
  .sret_trap_id_o                 (   sret_trap_id_o                    ),
  .s_trap_cause_wb_i              (   o_scause_rob                      ),
  .s_trap_pc_wb_i                 (   rob_instr_pc                      ),
  .s_trap_tval_wb_i               (   o_stval_rob                       ),
  .stvec_id_o                     (   stvec_id_o                        ),
  .sepc_id_o                      (   sepc_id_o                         ),
  .itlb_miss_id_i                 (   itlb_miss_if_o                    ),
  .itlb_miss_id_o                 (   itlb_miss_id_o                    ),
  //ROB
  .instr_valid_id_i(instr_valid_if_o),
  .rob_full_id_i(o_rob_full),
  .alloc_en_id_o(alloc_en_id_o),
  .alloc_rd_id_o(alloc_rd_id_o),
  .alloc_wr_en_id_o(alloc_wr_en_id_o),
  .alloc_is_store_id_o(alloc_is_store_id_o),
  .rob_tag_id_i(o_alloc_tag),
  .rs1_rob_tag_id_o(rs1_rob_tag_id_o), //Dependency check
  .rs2_rob_tag_id_o(rs2_rob_tag_id_o),
  .rs1_rob_valid_id_i(rs1_rob_valid),
  .rs2_rob_valid_id_i(rs2_rob_valid),
  .rs1_rob_value_id_i(rs1_rob_value_id_i),
  .rs2_rob_value_id_i(rs2_rob_value_id_i),
  .rs1_rob_busy_id_i(rs1_rob_busy),
  .rs2_rob_busy_id_i(rs2_rob_busy),
  .rob_tag_id_o(rob_tag_id_o),
  .instr_valid_id_o(instr_valid_id_o),
  //ROB COMMIT
  .rob_commit_we_id_i(rob_commit_we),
  .rob_commit_rd_label_id_i(rob_commit_rd_label),
  .rob_commit_data_id_i(rob_commit_data),
  .rob_commit_valid_id_i(rob_commit_valid),
  .rob_commit_tag_id_i(rob_commit_tag),
  //Pipeline Control Signals
  .rob_flush_id_i(rob_flush),
  .rob_exception_id_i(rob_exception),
  .rob_sret_id_i(rob_sret),
  .branching_id_i                 (   branching_ex_o                    ),
  .peripheral_stall_id_i          (   peripheral_stall_mem_o            ),
  .mem_stage_stall_i              (   mem_stage_stall                   )
);

instruction_execution ex_u
(
  .clk_i                          (   clk_i                             ),
  .rst_i                          (   rst_i                             ),
  //Inputs from Instruction Decode Stage
  .rs1_data_ex_i                  (   rs1_data_id_o                     ),
  .rs2_data_ex_i                  (   rs2_data_id_o                     ),
  .rd_label_ex_i                  (   rd_label_id_o                     ),
  .rs1_label_ex_i                 (   rs1_label_id_o                    ),
  .rs2_label_ex_i                 (   rs2_label_id_o                    ),
  .imm_value_ex_i                 (   imm_value_id_o                    ),
  .load_stall_ex_i                (   load_stall_id_o                   ),
  .rob_arbiter_stall_ex_i(alu_arbiter_stall),
  .load_store_forward_sel_ex_i    (   load_store_forward_sel_id_o       ),
  .reg_write_en_ex_i              (   reg_write_en_id_o                 ),
  .rs1_pc_imm_sel_ex_i            (   rs1_pc_imm_sel_id_o               ),
  .rs2_imm_csr_sel_ex_i           (   rs2_imm_csr_sel_id_o              ),
  .is_branch_instr_ex_i           (   is_branch_instr_id_o              ),
  .is_store_instr_ex_i            (   is_store_instr_id_o               ),
  .is_load_instr_ex_i             (   is_load_instr_id_o                ),
  .wb_sel_ex_i                    (   wb_sel_id_o                       ),
  .alu_op_ex_i                    (   alu_op_id_o                       ),
  .pc_ex_i                        (   pc_id_o                           ),
  .funct3_ex_i                    (   funct3_id_o                       ),
  .unconditional_branch_ex_i      (   unconditional_branch_id_o         ),
  .btb_predicted_pc_ex_i          (   btb_predicted_pc_id_o             ),
  .branch_is_taken_prediction_ex_i(   branch_is_taken_prediction_id_o   ),
  .fetched_instruction_ex_i       (   fetched_instruction_id_o          ),
  .ex_unit_sel_ex_i               (   ex_unit_sel_id_o                  ),
  .itlb_wr_en_ex_i                (   itlb_wr_en_id_o                   ),
  .itlb_wr_en_ex_o                (   itlb_wr_en_ex_o                   ),
  .dtlb_wr_en_ex_i                (   dtlb_wr_en_id_o                   ),
  .dtlb_wr_en_ex_o                (   dtlb_wr_en_ex_o                   ),
  
  .sb_id_ex_i                     (   sb_id_o                           ),
  //Outputs to Decode Stage
  .ex_stage_result_o              (   rd_value_ex_o                     ),
  .mdu_stall_ex_o                 (   mdu_stall_ex                      ),
  //Outputs to Memory Stage
  .alu_result_ex_o                (   alu_result_ex_o                   ),
  .load_store_forward_sel_ex_o    (   load_store_forward_sel_ex_o       ),
  .reg_write_en_ex_o              (   reg_write_en_ex_o                 ),
  .is_load_instr_ex_o             (   is_load_instr_ex_o                ),
  .is_store_instr_ex_o            (   is_store_instr_ex_o               ),
  .rd_label_ex_o                  (   rd_label_ex_o                     ),
  .wb_sel_ex_o                    (   wb_sel_ex_o                       ),
  .pc_ex_o                        (   pc_ex_o                           ),
  .funct3_ex_o                    (   funct3_ex_o                       ),
  .latest_rs2_value_ex_o          (   latest_rs2_value_ex_o             ),
  .fetched_instruction_ex_o       (   fetched_instruction_ex_o          ),
  .sb_id_ex_o                     (   sb_id_ex_o                        ),
  .imm_value_ex_o                 (   imm_value_ex_o                    ),
  .rs1_value_ex_o                 (   rs1_value_ex_o                    ),
  .csr_wr_en_ex_o                 (   csr_wr_en_ex_o                    ),
  //Inputs From Memory Stage
  .reg_write_en_mem_i             (   reg_write_en_ex_o                 ),
  .rd_label_mem_i                 (   rd_label_ex_o                     ),
  .alu_result_mem_i               (   alu_result_ex_o                   ),
  .rd_value_mem_i                 (   rd_value_mem_wo                   ), //rd's selected value
  .rd_value_wb_i                  (   rd_value_mem_ro                   ),
  //Inputs From WriteBack Stage
  .reg_write_en_wb_i              (   reg_write_en_mem_o                ),
  .rd_label_wb_i                  (   rd_label_mem_o                    ),
  //CSR Signals
  .csr_wr_en_ex_i                 (   csr_wr_en_id_o                    ),
  .csr_addr_ex_i                  (   csr_addr_id_o                     ),
  .csr_addr_ex_o                  (   csr_addr_ex_o                     ),
  .csr_rd_value_ex_i              (   csr_rd_value_id_o                 ),
  .csr_rd_value_ex_o              (   csr_rd_value_ex_o                 ),
  .ecall_trap_ex_i                (   ecall_trap_id_o                   ),
  .ebreak_trap_ex_i               (   ebreak_trap_id_o                  ),
  .ecall_trap_ex_o                (   ecall_trap_ex_o                   ),
  .ebreak_trap_ex_o               (   ebreak_trap_ex_o                  ),
  .sret_trap_ex_i                 (   sret_trap_id_o                    ),
  .sret_trap_ex_o                 (   sret_trap_ex_o                    ),
  .trap_en_ex_i                   (   rob_exception                     ),
  .itlb_miss_ex_i                 (   itlb_miss_id_o                    ),
  .itlb_miss_ex_o                 (   itlb_miss_ex_o                    ),
  //ROB
  .rob_tag_ex_i(rob_tag_id_o),
  .rob_tag_ex_o(rob_tag_ex_o),
  .instr_valid_ex_i(instr_valid_id_o),
  .instr_valid_ex_o(instr_valid_ex_o),
  .rob_commit_alu_done_ex_o(rob_commit_alu_done_ex_o),
  .rob_commit_tag_ex_o(rob_commit_tag_ex_o),
  .rob_commit_data_ex_o(rob_commit_data_ex_o),
  .rob_commit_exception_ex_o(rob_commit_exception_ex_o),
  .rob_commit_scause_ex_o(rob_commit_scause_ex_o),
  .rob_commit_stval_ex_o(rob_commit_stval_ex_o),
  .rob_commit_branch_ex_o(rob_commit_branch_ex_o),
  .rob_commit_branch_address_ex_o(rob_commit_branch_address_ex_o),
  .rob_commit_sret_ex_o(rob_commit_sret_ex_o),
  .rob_commit_csr_addr_ex_o(rob_commit_csr_addr_ex_o),
  .rob_commit_csr_wr_en_ex_o(rob_commit_csr_wr_en_ex_o),
  .rob_commit_rs1_ex_o(rob_commit_rs1_ex_o),
  .rob_commit_rs2_ex_o(rob_commit_rs2_ex_o),
  .rob_commit_itlb_wr_en_ex_o(rob_commit_itlb_wr_en_ex_o),
  .rob_commit_dtlb_wr_en_ex_o(rob_commit_dtlb_wr_en_ex_o),
  .rob_commit_unconditional_branch_ex_o(rob_commit_unconditional_branch_ex_o),
  .rob_arbiter_stall_mdu_ex_i(mdu_arbiter_stall),
  .rob_commit_mdu_done_ex_o(rob_commit_mdu_done_ex_o),
  .rob_commit_mdu_tag_ex_o(rob_commit_mdu_tag_ex_o),
  .rob_commit_mdu_result_o(rob_commit_mdu_result_o),
  // .rob_flush_ex_i(rob_flush),
  // Multi-Usage Output
  .branching_ex_o                 (   branching_ex_o                    ),
  .branch_address_ex_o            (   branch_address_ex_o               ),
  .increment_counter_ex_o         (   increment_counter_ex_o            ),
  .decrement_counter_ex_o         (   decrement_counter_ex_o            ),
  .update_btb_address_ex_o        (   update_btb_address_ex_o           ),
  .periheral_stall_ex_i           (   peripheral_stall_mem_o            ),
  .mem_stage_stall_i              (   mem_stage_stall                   )
);

instruction_memory_stage mem_u
(
  .clk_i                       (   clk_i                          ),
  .rst_i                       (   rst_i                          ),
  //Inputs From Execution stage
  .alu_result_mem_i            (   alu_result_ex_o                ),
  .load_store_forward_sel_mem_i(   load_store_forward_sel_ex_o    ),
  .reg_write_en_mem_i          (   reg_write_en_ex_o              ),
  .rd_label_mem_i              (   rd_label_ex_o                  ),
  .wb_sel_mem_i                (   wb_sel_ex_o                    ),
  .pc_mem_i                    (   pc_ex_o                        ),
  .pc_mem_o                    (   pc_mem_o                       ),
  .funct3_mem_i                (   funct3_ex_o                    ),
  .is_store_mem_i              (   is_store_instr_ex_o            ),
  .is_load_mem_i               (   is_load_instr_ex_o             ),
  .rs1_mem_i                   (   rob_commit_rs1                 ),
  .rs2_mem_i                   (   rob_commit_rs2                 ),
  .latest_rs2_value_mem_i      (   latest_rs2_value_ex_o          ),
  .fetched_instruction_mem_i   (   fetched_instruction_ex_o       ),
  .sb_id_mem_i                 (   sb_id_ex_o                     ),
  .rs1_mem_o                   (   rs1_mem_o                      ), //Used for ITLB
  .rs2_mem_o                   (   rs2_mem_o                      ), //Used for ITLB
  .csr_wr_en_mem_i             (   csr_wr_en_ex_o                 ),
  .alu_result_mem_o            (   alu_result_mem_o               ),
  //Inputs for CSR
  .ecall_trap_mem_i            (   ecall_trap_ex_o                ),
  .ebreak_trap_mem_i           (   ebreak_trap_ex_o               ),
  .ecall_trap_mem_o            (   ecall_trap_mem_o               ),
  .ebreak_trap_mem_o           (   ebreak_trap_mem_o              ),
  .sret_trap_mem_i             (   sret_trap_ex_o                 ),
  .sret_trap_mem_o             (   sret_trap_mem_o                ),
  .trap_en_mem_i               (   rob_exception | rob_flush | rob_sret ),
  .itlb_wr_en_mem_i            (   itlb_wr_en_ex_o                ),
  .dtlb_wr_en_mem_i            (   rob_commit_dtlb_wr_en                ),
  .itlb_wr_en_mem_o            (   itlb_wr_en_mem_o               ),
  .dtlb_wr_en_mem_o            (   dtlb_wr_en_mem_o               ),
  .load_page_fault_mem_o       (   load_page_fault_mem_o          ),
  .store_page_fault_mem_o      (   store_page_fault_mem_o         ),
  .execution_mode_mem_i        (   current_execution_mode         ),
  //Outputs To WriteBack Stage
  .load_value_mem_o            (   load_value_mem_o               ),
  .rd_label_mem_o              (   rd_label_mem_o                 ),
  .reg_write_en_mem_o          (   reg_write_en_mem_o             ),
  .wb_sel_mem_o                (   wb_sel_mem_o                   ),
  .is_load_mem_o               (   is_load_mem_o                  ),
  .rd_value_mem_ro             (   rd_value_mem_ro                ),
  .rd_value_mem_wo             (   rd_value_mem_wo                ), //Wire Output  
  //Inputs From Writeback Stage    
  .load_value_wb_i             (   load_value_mem_o               ),
  //Trap and CSR Outputs
  .csr_wr_en_mem_o             (   csr_wr_en_mem_o                ),
  .csr_addr_mem_i              (   csr_addr_ex_o                  ),
  .csr_addr_mem_o              (   csr_addr_mem_o                 ),
  .csr_rd_value_mem_i          (   csr_rd_value_ex_o              ),
  .csr_rd_value_mem_o          (   csr_rd_value_mem_o             ),
  .itlb_miss_mem_i             (itlb_miss_ex_o                    ),
  .itlb_miss_mem_o             (itlb_miss_mem_o                   ),
  //ROB Signals
  .rob_tag_mem_i(rob_tag_ex_o),
  .rob_tag_mem_o(rob_tag_mem_o),
  .instr_valid_mem_i(instr_valid_ex_o),
  .instr_valid_mem_o(instr_valid_mem_o),
  .rob_flush_mem_i(rob_flush),
  .rob_exception_mem_i(rob_exception),
  .rob_sret_mem_i(rob_sret),
  .rob_commit_mem_done_mem_o(rob_commit_mem_done_mem_o),
  .rob_commit_exception_mem_o(rob_commit_exception_mem_o),
  .rob_commit_scause_mem_o(rob_commit_scause_mem_o),
  .rob_commit_stval_mem_o(rob_commit_stval_mem_o),
  .rob_commit_tag_mem_o(rob_commit_tag_mem_o),
  .rob_drain_req_mem_i(o_rob_sb_drain),
  .rob_commit_data_mem_o(rob_commit_data_mem_o),
  .sb_resp_done_mem_o(sb_resp_done_mem_o),
  
  //Wisbone + Peripherals
  .peripheral_stall_o          (   peripheral_stall_mem_o         ),
  .mem_stage_stall_o           (   mem_stage_stall                ),
  .fetched_instruction_mem_o   (            ),

  //dcache request handshake
  .dcache_req_valid_mem_o(dcache_req_valid_mem_o),
  .dcache_req_valid_mem_i(dcache_req_ready_o),
  .dcache_address_mem_o(dcache_address_mem_o),
  .dcache_rd_wr_mem_o(dcache_rd_wr_mem_o),
    //-------------------------------------------
  .dcache_resp_valid_mem_i(dcache_resp_valid_o),
  .ram_response_id_mem_i(arb_req_id_o),
  .dcache_data_ready_mem_o(dcache_data_ready_mem_o),
  .dcache_line_fill_mem_i(dcache_line_fill_data_o),
  .dcache_line_evict_mem_o(dcache_line_evict_mem_o)
);

//Write Back Stage is Implicitly Here

//This block generates *cause, *tval 
// always @* begin
//   // exception_raised = 1'b0;
//   scause           = 32'b0;
//   stval            = 32'b0;
//   if(ebreak_trap_mem_o) begin
//     scause = {1'b0, 31'd3}; //Breakpoint Has Trap Code = 3
//     // exception_raised = 1'b1;
//     stval            = 32'b0;
//   end else if(ecall_trap_mem_o) begin //Ecall has a trap Code of 8
//     // exception_raised = 1'b1;
//     stval            = 32'b0;
//     case (current_execution_mode)
//       `U_MODE: scause = {1'b0, 31'd8}; //ecall from UMODE has cause 8 
//       `S_MODE: scause = {1'b0, 31'd9};
//       `M_MODE: scause = {1'b0, 31'd11}; //Probably, should assign mcause, TODO
//       default: scause = 32'b0;
//     endcase
//   end else if(itlb_miss_mem_o) begin //itlb miss
//     // exception_raised = 1'b1;
//     scause = {1'b0, 31'd12}; //instruction page fault
//     stval  = pc_mem_o;
//   end else if(store_page_fault_mem_o) begin //load page fault = 13, store page fault =  15
//     // exception_raised = 1'b1;
//     scause = {1'b0, 31'd13};
//     stval = alu_result_mem_o;
//   end else if(load_page_fault_mem_o) begin
//     // exception_raised = 1'b1;
//     scause = {1'b0, 31'd15};
//     stval = alu_result_mem_o;
//   end
// end



arbiter arbiter_u(
  .clk_i(clk_i),
  .rst_i(rst_i),
  //dcache interface
  .dcache_req_valid_i(dcache_req_valid_mem_o),
  .dcache_req_ready_o(dcache_req_ready_o), 
  .dcache_address_i(dcache_address_mem_o), //dcache line to be written/Read to/from ram
  .dcache_rd_wr_i(dcache_rd_wr_mem_o), //0 =Read, 1=Write
  .dcache_data_ready_i(dcache_data_ready_mem_o), //dcache is ready to receive RAM data
  //icache request signals----------------------------------------------------------
  .icache_req_valid_i ( icache_req_valid_if_o    ), //Cache request data
  .icache_req_ready_o ( icache_req_ready_o       ), //Cache transaction is ready to be served
  .icache_address_i   ( icache_fill_rd_addr      ),
  //--------------------------------------------------------------------------------
  //icache respond signals
  .icache_data_ready_i(icache_data_ready_if_o), //icache is ready to receive data
  //------------------------------------------------------------------------------
  //RAM interface
  .ram_ready_i(arb_req_ready_o), //Ram is ready to receive new request
  .ram_data_valid_i(ram_data_valid_o), //To clear the active transaction and accept new
  .arb_req_valid_o(arb_req_valid_o),
  .arb_address_o(arb_address_o),
  // .arb_data_in_o(),
  .arb_rd_wr_o(arb_rd_wr_o),
  .arb_req_id_o(arb_req_id_o),
  .cache_ready_o(cache_ready_o), //Requester cache is ready to receieve
  .dcache_resp_valid_o(dcache_resp_valid_o), //When RAM is valid, Check the request ID and fires the corresponding one
  .icache_resp_valid_o(icache_resp_valid_o),
  // .branching_i(branching_ex_o),
  .exception_raised_i(rob_sret | rob_exception | rob_flush)
  );



RAM #(
  .I_ENTRIES(I_ENTRIES),
  .I_WORDS_PER_LINE(I_WORDS_PER_LINE),
  .INSTRUCTION_WIDTH(INSTRUCTION_WIDTH)
)
RAM_u(
  .clk_i(clk_i),
  .rst_i(rst_i),
  //RAM <----> Arbiter 
  .arb_req_valid_i  ( arb_req_valid_o  ), //we have a request from arbiter, Can be read/write, icache/dcache
  .arb_req_ready_o  ( arb_req_ready_o), //RAM ready to receieve new request
  .arb_address_i    ( arb_address_o       ), // Fill request Address
  .arb_rd_wr_i      (arb_rd_wr_o), //Cache is a Read/Write request  0 = Read, 1 = Write
  .arb_req_id_i     (arb_req_id_o), //icache or dcache request, 0 = icache, 1 = dcache
  .arb_cache_ready_i(cache_ready_o),
  //--------------------------------------------------------------
  
  .ram_data_valid_o         ( ram_data_valid_o ), //Fill request is Done (Write to icache array)
  .icache_line_fill_data_o  ( icache_line_fill_data ), //icache line read from RAM (Allocate)
  .dcache_line_fill_data_o  ( dcache_line_fill_data_o ), //dcache line read from RAM (Allocate)
  .dcache_line_evict_mem_i (dcache_line_evict_mem_o),// dcache line written to RAM (Writeback)
  // .branching_i              ( branching_ex_o        ), // If we have branch, Abort the request
  .exception_raised_i(rob_sret | rob_exception | rob_flush) //SRET and Exception Raised clears RAM
  
);

//ROB entry arbitration between MEM, ALU
wire mem_request, alu_request, mdu_request;
reg cdb_valid, cdb_exc;
reg [3:0] cdb_tag;
reg [31:0] cdb_data;
reg [31:0] cdb_scause, cdb_stval;
reg [31:0]  cdb_branch_address;
reg cdb_sret;
reg cdb_branch;
reg alu_arbiter_stall;
reg cdb_is_store;
reg [11:0] cdb_csr_addr;
reg cdb_csr_wr_en;
reg [31:0] cdb_rs1, cdb_rs2;
reg cdb_itlb_wr_en, cdb_dtlb_wr_en;
reg mdu_arbiter_stall;
reg cdb_unconditional_branch;
// reg mdu_request;
assign alu_request = rob_commit_alu_done_ex_o;
assign mdu_request = rob_commit_mdu_done_ex_o;
assign mem_request = rob_commit_mem_done_mem_o;
always @* begin
  cdb_valid = 1'b0;
  cdb_tag   = 1'b0;
  cdb_exc   = 1'b0;
  cdb_data  = 32'b0;
  cdb_scause = 32'b0;
  cdb_stval  = 32'b0;
  cdb_branch = 1'b0;
  cdb_branch_address  = 32'b0;
  alu_arbiter_stall  = 1'b0;
  cdb_sret          = 1'b0;
  cdb_csr_addr      = '1;
  cdb_csr_wr_en = 1'b0;
  cdb_rs1 = 0;
  cdb_rs2 = 0;
  cdb_itlb_wr_en = 1'b0;
  cdb_dtlb_wr_en = 1'b0;
  mdu_arbiter_stall = 1'b0;
  cdb_unconditional_branch = 1'b0;
  if(mem_request) begin
    cdb_valid = 1'b1;
    cdb_tag = rob_commit_tag_mem_o;
    //cdb_tag DATA
    cdb_exc = rob_commit_exception_mem_o;
    cdb_scause = rob_commit_scause_mem_o;
    cdb_stval  = rob_commit_stval_mem_o;
    cdb_data   = rob_commit_data_mem_o;
    if(alu_request) begin //We have contention for the BUS, Priority to MEM
      alu_arbiter_stall = 1'b1;
    end
    if(mdu_request) begin
      mdu_arbiter_stall = 1'b1;
    end
  end else if(mdu_request) begin
    cdb_valid = 1'b1;
    cdb_data = rob_commit_mdu_result_o;
    cdb_tag = rob_commit_mdu_tag_ex_o;
    if(alu_request) begin //We have contention for the BUS, Priority to MEM
      alu_arbiter_stall = 1'b1;
    end
  end  else if(alu_request) begin
    cdb_valid  = 1'b1;
    cdb_tag    = rob_commit_tag_ex_o;
    cdb_data   = rob_commit_data_ex_o;
    cdb_exc    = rob_commit_exception_ex_o;
    cdb_scause = rob_commit_scause_ex_o;
    cdb_stval  = rob_commit_stval_ex_o;
    cdb_branch = rob_commit_branch_ex_o;
    cdb_branch_address = rob_commit_branch_address_ex_o;
    cdb_sret = rob_commit_sret_ex_o;
    cdb_csr_addr = rob_commit_csr_addr_ex_o;
    cdb_csr_wr_en    = rob_commit_csr_wr_en_ex_o;
    cdb_rs1 = rob_commit_rs1_ex_o;
    cdb_rs2 = rob_commit_rs2_ex_o;
    cdb_itlb_wr_en = rob_commit_itlb_wr_en_ex_o;
    cdb_dtlb_wr_en = rob_commit_dtlb_wr_en_ex_o;
    cdb_unconditional_branch = rob_commit_unconditional_branch_ex_o;
  end
end

wire rob_commit_we;
wire [4:0] rob_commit_rd_label;
wire [31:0] rob_commit_data;
wire [31:0] rob_commit_pc, rob_commit_instr;
wire rob_commit_valid;
wire [3:0] rob_commit_tag;
wire rob_flush;
wire [31:0] rob_flush_pc;
wire rob_exception,rob_sret;
wire [31:0] o_stval_rob, o_scause_rob,rob_instr_pc;
wire rs1_rob_busy, rs2_rob_busy;
wire o_rob_sb_drain;
wire rob_commit_csr_wr_en;
wire [11:0] rob_commit_csr_addr;
wire [31:0] rob_commit_rs1, rob_commit_rs2;
wire rob_commit_itlb_wr_en, rob_commit_dtlb_wr_en;
rob #(
  .ROB_SIZE(16),
  .DATA_WIDTH(32),
  .ADDR_WIDTH(5)
)
rob_u(
  .i_clk(clk_i),
  .i_rst(rst_i),
  //Instruction Allocation Signals
  .i_alloc_en(alloc_en_id_o),
  .i_alloc_rd(alloc_rd_id_o), //ID rd label
  .i_alloc_we(alloc_wr_en_id_o), // ID reg wr en
  .i_alloc_pc(pc_incremented_if_o),
  .i_alloc_instr(fetched_instruction_if_o), //For debug
  .i_alloc_is_store(alloc_is_store_id_o),
  .o_alloc_tag(o_alloc_tag), //index assign to this instruction
  .o_rob_full(o_rob_full),

  //Forwarding Signals
  .i_rs1_rob_tag(rs1_rob_tag_id_o),
  .i_rs2_rob_tag(rs2_rob_tag_id_o),
  .o_rs1_valid(rs1_rob_valid),
  .o_rs2_valid(rs2_rob_valid),
  .o_rs1_busy(rs1_rob_busy),
  .o_rs2_busy(rs2_rob_busy),
  .o_rs1_value(rs1_rob_value_id_i),
  .o_rs2_value(rs2_rob_value_id_i),
  //CDB
  .i_cdb_valid  (cdb_valid  ), //ALU op Done
  .i_cdb_tag    (cdb_tag    ), // which ROB entry
  .i_cdb_result (cdb_data   ), // Result
  .i_cdb_exc    (cdb_exc    ), //Exceptions
  .i_cdb_sret   (cdb_sret   ),
  .i_cdb_scause (cdb_scause ),
  .i_cdb_stval  (cdb_stval  ),
  .i_cdb_branch(cdb_branch),
  .i_cdb_branch_address(cdb_branch_address),
  .i_cdb_csr_addr(cdb_csr_addr),
  .i_cdb_csr_wr(cdb_csr_wr_en),
  .i_cdb_rs1(cdb_rs1),
  .i_cdb_rs2(cdb_rs2),
  .i_cdb_itlb_wr_en(cdb_itlb_wr_en),
  .i_cdb_dtlb_wr_en(cdb_dtlb_wr_en),
  .i_cdb_unconditional_branch(cdb_unconditional_branch),
  .i_sb_drain_done(sb_resp_done_mem_o),


  //Commit interface
  .o_commit_we(rob_commit_we), //Register Reg Wr En
  .o_commit_rd(rob_commit_rd_label), //Register Label
  .o_commit_data(rob_commit_data), //Data written
  .o_commit_pc(rob_commit_pc), //PC of retiring instr
  .o_commit_valid(rob_commit_valid),
  .o_commit_rob_tag(rob_commit_tag),
  .o_commit_csr_wr_en(rob_commit_csr_wr_en),
  .o_commit_csr_addr(rob_commit_csr_addr),
  .o_commit_rs1(rob_commit_rs1),//for TLB write instructions!!
  .o_commit_rs2(rob_commit_rs2),
  .o_commit_itlb_wr_en(rob_commit_itlb_wr_en),
  .o_commit_dtlb_wr_en(rob_commit_dtlb_wr_en),
  .rob_commit_instr_o(fetched_instruction_wb),
  .o_flush(rob_flush),
  .o_exception(rob_exception),
  .o_sret(rob_sret),
  .o_flush_pc(rob_flush_pc),
  .o_instr_pc(rob_instr_pc),
  .o_scause_rob(o_scause_rob),
  .o_stval_rob(o_stval_rob),
  .o_rob_sb_drain(o_rob_sb_drain)
);

`ifdef COCOTB_SIM
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, core);
    end
`endif

`ifdef CORE_VERBOSITY
  int trace_file;
  int memory_dump;
  initial begin
    trace_file  = $fopen("trace_core.log", "w");
    memory_dump = $fopen("memory_dump.log","w");
  end
  `define IF_PATH if_u
  `define ID_PATH id_u
  `define EX_PATH ex_u
  `define MEM_PATH mem_u
  reg  [31:0] cycle_reg;
  wire [31:0] cycle_next;
  wire [31:0] termination_cycle;
  wire [127:0] current_execution_mode_str;
  reg [31:0] executed_instructions_reg;
  wire [31:0] executed_instructions_next;
  assign current_execution_mode_str = privilege_mode_converter(current_execution_mode);
  // always @(posedge clk_i) begin
  //   if(rst_i) begin
  //     cycle_reg <= 0;
  //   end else begin
  //     cycle_reg <= cycle_next;
  //   end
  // end

  // always @(posedge clk_i) begin
  //   if(rst_i) begin
  //     executed_instructions_reg <= 0;
  //   end else if(fetched_instruction_wb != 32'h13) begin
  //     executed_instructions_reg <= executed_instructions_next;
  //   end
  // end
  
  localparam PROGRAM_END = 32'h0000006f ;
  reg stop_counting;

  always @(posedge clk_i) begin
    if (rst_i) begin
      stop_counting             <= 1'b0;
      cycle_reg                 <= 32'b0;
      executed_instructions_reg <= 32'b0;
    end else if (!stop_counting) begin
      
      // Check if we just hit the end of the program
      if (fetched_instruction_wb == PROGRAM_END) begin
        stop_counting <= 1'b1;
      end else begin
        // Increment cycles every tick until stopped
        cycle_reg <= cycle_reg + 32'b1;

        // Increment instructions only if it's not a NOP
        if (fetched_instruction_wb != 32'h13) begin
          executed_instructions_reg <= executed_instructions_reg + 32'b1;
        end
      end

    end
  end

  // Now termination_cycle is simply the value held in cycle_reg
  assign termination_cycle = cycle_reg;
  // assign cycle_next = (fetched_instruction_wb == PROGRAM_END) ? cycle_reg : cycle_reg + 32'b1;
  // assign termination_cycle = (fetched_instruction_wb == PROGRAM_END) ? cycle_reg : termination_cycle;
  // assign cycle_next =  cycle_reg + 32'b1;
  // assign executed_instructions_next = executed_instructions_reg + 32'b1;
  always @(negedge clk_i) begin
  if(`CORE_VERBOSITY >= 100) begin
    $fwrite(trace_file,"\n");
    $fwrite(trace_file, "Cycle: %d, Privilege Mode: %0s", cycle_reg, current_execution_mode_str);
    // $fwrite(trace_file, "C: %d, TC: %0d, EI", cycle_reg, termination_cycle, executed_instructions_reg);
    if_u.if_trace_log(trace_file);
    // RAM_u.ram_trace_log(trace_file);
    // arbiter_u.arbiter_trace_log(trace_file);
    id_u.id_trace_log(trace_file);
    ex_u.ex_trace_log(trace_file);
    mem_u.mem_trace_log(trace_file,memory_dump,cycle_reg);
    // mem_u.mem_trace_log(trace_file,memory_dump,cycle_reg);
    rob_u.rob_trace_log(trace_file);
  end

  // `ifdef MEM_DUMP
    if(cycle_reg == 1 || cycle_reg == 70000000) begin
      RAM_u.memory_dump(memory_dump, cycle_reg);
    end
  // `endif
end
  
`endif

endmodule