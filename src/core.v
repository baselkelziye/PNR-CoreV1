`timescale 1ns / 1ps
/*
NOTES:
The wishbone slave is tested on the simulation, TX FIFO is filled on Store instructions and A Tmp value is read from UART_RD_REG on load instruction
The Hardware shall be tested on the FPGA
*/


/*
Assertions to be Added:

1- Branch Predictor Should Never Predict Taken if the Instruction is not a Branch (Add mini-decoder)
2- In WB Stage, An Exception Shouldn't fire if the Instruction is CSRRW (SPEC Take value from TRAP or Decode???)
*/

/*
Exception Shall Clear All stalls

*/

module core(
    input clk_i, rst_i
);

//Instruction Fetch Stage Variables
wire [31:0] pc_incremented_if_o;
wire [31:0] fetched_instruction_if_o;
wire [31:0] btb_predicted_pc_if_o;
wire branch_is_taken_prediction_if_o;
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
wire ecall_trap_ex_o, ebreak_ex_o;
wire sret_trap_ex_o;
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
//Wishbone + Peripherals
wire peripheral_stall_mem_o;
wire mem_stage_stall;
//--------------------------------------------

//WriteBack Stage Variable Declarations
wire [31:0] rd_value_wb_mem_o;
wire reg_write_en_wb_o;
wire [31:0] alu_result_wb_o, load_data_wb_o, pc_wb_o;
wire [31:0] fetched_instruction_wb;
// wire [31:0] pc_mem_o;
reg exception_raised;
reg [31:0] scause;
reg [31:0] stval;

reg [1:0] current_execution_mode;

//On reset go to U_MODE, Isa goes to M Mode later to be modified
//Now, I only Do SRET to go back to u-mode, Later need to involve sstatus, mstatus.
always @(posedge clk_i, posedge rst_i) begin
  if(rst_i) begin
    current_execution_mode <= `U_MODE;
  end else begin
    if(exception_raised) begin
      //If Trap Happens go to higher privilege
      //Now i only go from U to S mode
      case (current_execution_mode)
        `U_MODE: current_execution_mode <= `S_MODE; 
        `S_MODE: current_execution_mode <= `M_MODE;
        `M_MODE: current_execution_mode <= `M_MODE;
        default: current_execution_mode <= `U_MODE;
      endcase
    end else if(sret_trap_mem_o) begin // Return to U-MODE
          current_execution_mode <= `U_MODE;
    end
  end
end


instruction_fetch if_u
(
  .clk_i                          (   clk_i                             ),
  .rst_i                          (   rst_i                             ),
  .fetched_instruction_if_o       (   fetched_instruction_if_o          ),
  .pc_incremented_if_o            (   pc_incremented_if_o               ),
  //Inputs From  Instruction Decode Stage For Load Hazard
  .load_stall_if_i                (   load_stall_id_o                   ),
  //Inputs From Execution Stage For Branching,
  .branching_i                    (   branching_ex_o                    ),
  .branching_address_i            (   branch_address_ex_o               ),
  //Inputs From Execution Stage For Branch Prediction
  .is_branch_instr_ex_i           (   is_branch_instr_id_o              ), // The output reg of id =  is equal to ex_wire
  .decrement_counter_i            (   decrement_counter_ex_o            ),
  .increment_counter_i            (   increment_counter_ex_o            ),
  .pc_ex_i                        (   pc_id_o                           ),
  .mdu_stall_ex_i                 (   mdu_stall_ex                      ),
  //Trap Signals
  .stvec_csr_i                    (   stvec_id_o                       ),
  .trap_en_if_i                   (   exception_raised                  ),
  .sret_trap_wb_i                 (   sret_trap_mem_o                   ),
  .trap_return_pc_i               (   sepc_id_o                         ),
  .current_execution_mode_if_i    (   current_execution_mode            ),
  //Outputs For Branch Prediction
  .btb_predicted_pc_if_o          (   btb_predicted_pc_if_o             ),
  .branch_is_taken_prediction_if_o(   branch_is_taken_prediction_if_o   ),
  .periheral_stall_if_i           (   peripheral_stall_mem_o            ),
  .mem_stage_stall_i              (   mem_stage_stall                   )
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
  .trap_en_id_i                   (   exception_raised                  ),
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
  .csr_wr_en_wb_i                 (   csr_wr_en_mem_o                   ),
  .csr_wr_addr_wb_i               (   csr_addr_mem_o                    ),
  .csr_rd_value_wb_i              (   csr_rd_value_mem_o                ),
  .csr_wr_en_o                    (   csr_wr_en_id_o                    ),
  .csr_addr_id_o                  (   csr_addr_id_o                     ),
  .csr_rd_value_id_o              (   csr_rd_value_id_o                 ),
  .ecall_trap_id_o                (   ecall_trap_id_o                   ),
  .ebreak_trap_id_o               (   ebreak_trap_id_o                  ),
  .sret_trap_id_o                 (   sret_trap_id_o                    ),
  .s_trap_cause_wb_i              (   scause                            ),
  .s_trap_pc_wb_i                 (   pc_mem_o                          ),
  .s_trap_tval_wb_i               (   stval                             ),
  .stvec_id_o                     (   stvec_id_o                        ),
  .sepc_id_o                      (   sepc_id_o                         ),
  //Pipeline Control Signals
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
  .trap_en_ex_i                   (   exception_raised                  ),
  // Multi-Usage Output
  .branching_ex_o                 (   branching_ex_o                    ),
  .branch_address_ex_o            (   branch_address_ex_o               ),
  .increment_counter_ex_o         (   increment_counter_ex_o            ),
  .decrement_counter_ex_o         (   decrement_counter_ex_o            ),
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
  .latest_rs2_value_mem_i      (   latest_rs2_value_ex_o          ),
  .fetched_instruction_mem_i   (   fetched_instruction_ex_o       ),
  .sb_id_mem_i                 (   sb_id_ex_o                     ),
  .csr_wr_en_mem_i             (   csr_wr_en_ex_o                 ),
  //Inputs for CSR
  .ecall_trap_mem_i            (   ecall_trap_ex_o                ),
  .ebreak_trap_mem_i           (   ebreak_trap_ex_o               ),
  .ecall_trap_mem_o            (   ecall_trap_mem_o               ),
  .ebreak_trap_mem_o           (   ebreak_trap_mem_o              ),
  .sret_trap_mem_i             (   sret_trap_ex_o                 ),
  .sret_trap_mem_o             (   sret_trap_mem_o                ),
  .trap_en_mem_i               (   exception_raised               ),
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
  //Wisbone + Peripherals
  .peripheral_stall_o          (   peripheral_stall_mem_o         ),
  .mem_stage_stall_o           (   mem_stage_stall                ),
  .fetched_instruction_mem_o   (   fetched_instruction_wb         )
);

//Write Back Stage is Implicitly Here

//This block generates *cause, *tval 
always @* begin
  exception_raised = 1'b0;
  scause           = 32'b0;
  stval            = 32'b0;
  if(ebreak_trap_mem_o) begin
    scause = {1'b0, 30'd3}; //Breakpoint Has Trap Code = 3
    exception_raised = 1'b1;
    stval            = 32'b0;
  end else if(ecall_trap_mem_o) begin //Ecall has a trap Code of 8
    exception_raised = 1'b1;
    stval            = 32'b0;
    case (current_execution_mode)
      `U_MODE: scause = {1'b0,30'd8}; //ecall from UMODE has cause 8 
      `S_MODE: scause = {1'b0,30'd9};
      `M_MODE: scause = {1'b0, 30'd11}; //Probably, should assign mcause, TODO
      default: scause = 32'b0;
    endcase
  end else begin //Later add
    exception_raised = 1'b0;
    scause           = 32'b0;
    stval            = 32'b0;
  end
end


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
  wire [127:0] current_execution_mode_str;
  reg [31:0] executed_instructions_reg;
  wire [31:0] executed_instructions_next;
  assign current_execution_mode_str = privilege_mode_converter(current_execution_mode);
  always @(posedge clk_i) begin
    if(rst_i) begin
      cycle_reg <= 0;
    end else begin
      cycle_reg <= cycle_next;
    end
  end

  always @(posedge clk_i) begin
    if(rst_i) begin
      executed_instructions_reg <= 0;
    end else if(fetched_instruction_wb != 32'h13) begin
      executed_instructions_reg <= executed_instructions_next;
    end
  end
  localparam PROGRAM_END = 32'h0000006f ;
  // assign cycle_next = (fetched_instruction_wb == PROGRAM_END) ? cycle_reg : cycle_reg + 32'b1;
  assign cycle_next =  cycle_reg + 32'b1;
  assign executed_instructions_next = executed_instructions_reg + 32'b1;
  always @(negedge clk_i) begin
  if(`CORE_VERBOSITY >= 100) begin
    $fwrite(trace_file,"\n");
    $fwrite(trace_file, "Cycle: %d, Privilege Mode: %0s", cycle_reg, current_execution_mode_str);
    if_u.if_trace_log(trace_file);
    id_u.id_trace_log(trace_file);
    ex_u.ex_trace_log(trace_file);
    mem_u.mem_trace_log(trace_file,memory_dump,cycle_reg);
    // mem_u.mem_trace_log(trace_file,memory_dump,cycle_reg);
  end
end
  
`endif

endmodule