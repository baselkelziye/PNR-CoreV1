`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2024 11:18:05 AM
// Design Name: 
// Module Name: instruction_decode
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


module instruction_decode(
  input clk_i, rst_i,
    
  //Inputs from Instruction Fetch Stage
    input [31:0] fetched_instruction_id_i,
    input [31:0] pc_id_i,
  input [31:0] btb_predicted_pc_id_i,
  input 		 branch_is_taken_prediction_id_i,
    
  //Register Related Signals
    output reg [31:0] rs1_data_id_o, rs2_data_id_o,
  output reg [4:0] rd_label_id_o, rs1_label_id_o, rs2_label_id_o,

  //Immediate Value
  output reg [31:0] imm_value_id_o,
  
  //Hazard Detection Unit 
  output reg  load_store_forward_sel_id_o,
  output wire load_stall_id_o,
  //Control Unit
  output reg reg_write_en_id_o,
  output reg [1:0] rs1_pc_imm_sel_id_o, rs2_imm_csr_sel_id_o,
  output reg is_branch_instr_id_o, is_store_instr_id_o, is_load_instr_id_o,
  output reg [1:0] wb_sel_id_o,
  output reg [3:0] alu_op_id_o,
  output reg unconditional_branch_id_o,
  output reg ex_unit_sel_o,
  output reg itlb_wr_en_id_o,
  output reg dtlb_wr_en_id_o,

  //Program Counter
  output reg [31:0] pc_id_o,
  output reg [31:0] fetched_instruction_id_o,
  
  //Instruction Extraction
  output reg [2:0] funct3_id_o,

  //Branch Prediction Outputs
  output reg [31:0] btb_predicted_pc_id_o,
  output reg branch_is_taken_prediction_id_o,

  //Outputs to ROB and SB
  output reg [7:0] sb_id_o,

  //Inputs From Execution Stage
  input wire is_load_instr_ex_i,
  input wire reg_write_en_ex_i,
  input wire [4:0] rd_label_ex_i,
  input wire [31:0] rd_value_ex_i,
  input wire mdu_stall_ex_i,

  //Inputs From Memory Stage
  input wire reg_write_en_mem_i,
  input wire [4:0] rd_label_mem_i,
  input wire [31:0] rd_value_mem_i,
  input wire is_load_instr_mem_i,
  
  //Inputs From Writeback stage
  input wire reg_write_en_wb_i,
  input wire [4:0] rd_label_wb_i,
  input wire [31:0] rd_value_wb_i,

  //Trap and CSR inputs,
  input wire csr_wr_en_wb_i, // Inputs from WB
  input wire [11:0] csr_wr_addr_wb_i,
  input wire [31:0] csr_rd_value_wb_i, //Value to be written in Register File
  output reg [31:0] csr_rd_value_id_o,
  output reg ecall_trap_id_o ,
  output reg ebreak_trap_id_o,
  output reg sret_trap_id_o,
  input [31:0] s_trap_cause_wb_i,
  input [31:0] s_trap_pc_wb_i,
  input [31:0] s_trap_tval_wb_i,
  output wire [31:0] stvec_id_o,
  output wire [31:0] sepc_id_o,
  input wire trap_en_id_i, //Exception Raised in WB
  input itlb_miss_id_i,
  output reg itlb_miss_id_o,
  //Outputs to EX
  output reg [11:0] csr_addr_id_o,
  output reg csr_wr_en_o,

  //Pipeline Control Signals
  input wire branching_id_i,

  //Inputs for Wishbone
  input wire peripheral_stall_id_i,
  input wire mem_stage_stall_i
);
    
localparam SB_ID_SIZE = 8;
//Definitions for Instruction Extraction
wire [4:0] rd_label, rs1_label, rs2_label;
wire [2:0] funct3;
wire [6:0] opcode, funct7;
  
//Read Register Values
wire [31:0] rs1_value, rs2_value;

//Immediate Result
wire [31:0] imm_value;
  
  
//Hazard Detection Unit Signals
wire load_stall, load_store_forward_sel;

//Control Unit Signals
wire reg_write_en, is_branch_instr;
wire [1:0] rs1_pc_imm_sel, rs2_imm_csr_sel;
wire is_load_instr, is_store_instr;
wire [1:0] wb_sel;
wire [2:0] imm_type;
wire [3:0] alu_op;
wire	unconditional_branch; 
wire id_stage_stall;
wire id_flush;
wire ex_unit_sel;
//Trap and CSR Signals

wire csr_wr_en;
wire [11:0] csr_addr;
wire [31:0] csr_rd_value;
wire ecall_trap, ebreak_trap;
wire sret_trap;
//Forwaring Signals
wire [1:0] forwardA, forwardB;
wire [31:0] rs1_forwarded_value, rs2_forwarded_value;

//Store ID
wire [SB_ID_SIZE-1:0] sb_id_next;
reg [SB_ID_SIZE-1:0] sb_id_reg;
    
//Extraction of Instruction fields
assign rd_label  = fetched_instruction_id_i[11:7 ];
assign rs1_label = fetched_instruction_id_i[19:15];
assign rs2_label = fetched_instruction_id_i[24:20];
assign funct3    = fetched_instruction_id_i[14:12];
assign funct7    = fetched_instruction_id_i[31:25];
assign opcode    = fetched_instruction_id_i[6:0  ];
assign csr_addr  = fetched_instruction_id_i[31:20];
    
    
assign load_stall_id_o = load_stall;
assign id_stage_stall  =  (peripheral_stall_id_i | mem_stage_stall_i | mdu_stall_ex_i) & ~trap_en_id_i; //If we have a Trap, Cancel Stall to let Bubble
assign id_flush        = load_stall | branching_id_i | trap_en_id_i;


//CSR wr_en signal indicates that 
wire [31:0] rf_wr_value = (csr_wr_en_wb_i) ? csr_rd_value_wb_i : rd_value_wb_i;
register_file register_file_u
(
    .clk_i          (   clk_i             ),
    .rst_i          (   rst_i             ),
    .rd_label_i     (   rd_label_wb_i     ),
    .rs1_label_i    (   rs1_label         ),
    .rs2_label_i    (   rs2_label         ),
    .reg_write_en_i (   reg_write_en_wb_i ), //To be filed from WB Stage
    .wr_data_i      (   rf_wr_value       ),
    .rs1_data_o     (   rs1_value         ),
    .rs2_data_o     (   rs2_value         )
);

csr csr_u(
  .clk_i            (   clk_i                           ),
  .rst_i            (   rst_i                           ),
  // Reads for this Stage
  .csr_rd_addr_i    (   csr_addr                        ), //This Will read the Register
  .csr_rd_data_o    (   csr_rd_value                    ),
  //Writes from WB
  .csr_wr_en_i      (   csr_wr_en_wb_i                  ),
  .csr_wr_addr_i    (   csr_wr_addr_wb_i                ),
  .csr_trap_wr_en_i (   trap_en_id_i                    ),//This Updates Registers That written by HW (SEPC etc)
  .s_trap_pc_i      (   s_trap_pc_wb_i                  ),
  .s_trap_cause_i   (   s_trap_cause_wb_i               ),
  .s_trap_tval      (   s_trap_tval_wb_i                ),
  .stvec_id_o       (   stvec_id_o                      ), //Output to Instruction Fetch
  .sepc_id_o        (   sepc_id_o                       ), //Output for trap return
  .csr_wr_value_i   (   rd_value_wb_i                   ) //CSR Wr value is from ALU, RF gets value from The Propagated CSR Value that have been read
);


forwarding_unit forwarding_unit_u(
  .rd_label_mem_wb_o (   rd_label_wb_i        ), // Rd Label From Write Back
  .reg_wb_en_mem_wb_o(   reg_write_en_wb_i    ), // Rd Reg En from Write Back
  .rd_label_id_ex_o  (   rd_label_ex_i        ), // Rd Label from EX Stage
  .reg_wb_en_id_ex_o (   reg_write_en_ex_i    ), // Reg En From EX Stage
  .rd_label_ex_mem_o (   rd_label_mem_i       ), // Rd Label from MEM Stage
  .reg_wb_en_ex_mem_o(   reg_write_en_mem_i   ), // Reg En from MEM Stage
  .rs1_label_id_i    (   rs1_label            ),
  .rs2_label_id_i    (   rs2_label            ),  
  .forwardA_o        (   forwardA             ),
  .forwardB_o        (   forwardB             )
);

mux_4x1 #(
  .DATA_WIDTH(32)
) rs1_latest_value_selector (
    .in0_i  (   rs1_value             ),
    .in1_i  (   rd_value_ex_i         ),
    .in2_i  (   rd_value_mem_i        ),
    .in3_i  (   rd_value_wb_i         ),
    .sel_i  (   forwardA              ),
    .out_o  (   rs1_forwarded_value   )
);

mux_4x1 #(
    .DATA_WIDTH(32)
) rs2_latest_value_selector(
    .in0_i  (   rs2_value             ),
    .in1_i  (   rd_value_ex_i         ),
    .in2_i  (   rd_value_mem_i        ),
    .in3_i  (   rd_value_wb_i         ),
    .sel_i  (   forwardB              ),
    .out_o  (   rs2_forwarded_value   )
);
        
  imm_gen imm_gen_u(
    .instr_i  (   fetched_instruction_id_i),
    .imm_src  (   imm_type                ),
    .imm_o    (   imm_value               )
);
    
  hazard_detection_unit hazard_detection_unit_u(
  .is_load_instruction_ex_i   (   is_load_instr_ex_i      ),
  .is_load_instruction_mem_i  (   is_load_instr_mem_i     ),
  .is_store_instruction_id_i  (   is_store_instr          ),
  .rd_label_ex_i              (   rd_label_ex_i           ),
  .rd_label_mem_i             (   rd_label_mem_i          ),
  .rs1_label_id_i             (   rs1_label               ),
  .rs2_label_id_i             (   rs2_label               ), 
  .stall_o                    (   load_stall              ),
  .load_store_forward_sel_o   (   load_store_forward_sel  )
);

wire itlb_wr_en, dtlb_wr_en;
  control_unit control_unit_u(
  .opcode_i               (   opcode[6:2]           ), //dismiss lower 2 bits
  .funct3_i               (   funct3                ),
  .funct7_i               (   funct7                ),
  .rs2_i                  (   rs2_label             ),
  .reg_write_en_o         (   reg_write_en          ),
  .wb_sel_o               (   wb_sel                ),
  .rs1_pc_imm_sel_o       (   rs1_pc_imm_sel        ),
  .rs2_imm_csr_sel_o      (   rs2_imm_csr_sel       ),
  .imm_type_o             (   imm_type              ),
  .is_branch_instr_o      (   is_branch_instr       ),
  .is_load_instr_o        (   is_load_instr         ),
  .is_store_instr_o       (   is_store_instr        ),
  .alu_op_o               (   alu_op                ),
  .unconditional_branch_o (   unconditional_branch  ),
  .ex_unit_sel_o          (   ex_unit_sel           ),
  .csr_wr_en_o            (   csr_wr_en             ),
  .ebreak_trap_o          (   ebreak_trap           ),
  .ecall_trap_o           (   ecall_trap            ),
  .sret_trap_o            (   sret_trap             ),
  .itlb_wr_en_o           (   itlb_wr_en            ),
  .dtlb_wr_en_o           (   dtlb_wr_en            )
);
   
always @(posedge clk_i, posedge rst_i) begin
  if(rst_i) begin
    sb_id_reg <= '0;
  end else if (!id_stage_stall) begin
    sb_id_reg <= sb_id_next;
  end
end

assign sb_id_next = (is_store_instr) ? sb_id_reg + 8'b1 : sb_id_reg;

   
always @(posedge clk_i, posedge rst_i)
begin
    if(rst_i)
    begin 
        rs1_data_id_o                  <= 32'h0 ;
        rs2_data_id_o                  <= 32'h0 ;
        imm_value_id_o         		  	 <= 32'h0 ;
        load_store_forward_sel_id_o      <= 1'b0  ;
        reg_write_en_id_o 	       		   <= 1'b0  ;
        rs1_pc_imm_sel_id_o 	               <= 2'b0  ;
        rs2_imm_csr_sel_id_o 	               <= 2'b0  ;
        is_branch_instr_id_o 	           <= 1'b0  ;
        is_store_instr_id_o 	           <= 1'b0  ;
        is_load_instr_id_o           	   <= 1'b0  ;
        wb_sel_id_o                      <= 2'b00 ;
        alu_op_id_o                      <= 4'b0  ;
        pc_id_o                          <= 32'h80000000;
        rd_label_id_o                    <= 5'b0  ;
        rs1_label_id_o                   <= 5'b0  ;
        rs2_label_id_o                   <= 5'b0  ;	
        funct3_id_o                      <= 3'b0  ;
        unconditional_branch_id_o        <= 1'b0  ;
        btb_predicted_pc_id_o            <= 32'h0 ;
        branch_is_taken_prediction_id_o  <= 1'b0  ;
        fetched_instruction_id_o         <= 32'h13;
        ex_unit_sel_o                    <= 1'b0;
        sb_id_reg                        <= '0;
        csr_wr_en_o                      <= 1'b0;
        csr_addr_id_o                    <= '0;
        csr_rd_value_id_o                <= '0;
        ecall_trap_id_o                  <= 1'b0;
        ebreak_trap_id_o                 <= 1'b0;
        sret_trap_id_o                   <= 1'b0;
        itlb_miss_id_o                   <= 1'b0;
        itlb_wr_en_id_o                  <= 1'b0;
        dtlb_wr_en_id_o                  <= 1'b0;
    end 
    else if(id_flush & !id_stage_stall) //If later Pipe is stalling, we shouldn't NOP otherwise we will lose the instruction in the next stage!
    begin // Komutu NOP'A cevirmek icin bunlar ytrli
        reg_write_en_id_o                <= 1'b0 ;
        is_store_instr_id_o              <= 1'b0 ;
        is_branch_instr_id_o             <= 1'b0 ;
        is_load_instr_id_o               <= 1'b0 ;
        unconditional_branch_id_o        <= 1'b0 ;
        btb_predicted_pc_id_o            <= 32'h0;
        branch_is_taken_prediction_id_o  <= 1'b0 ;
        fetched_instruction_id_o         <= 32'h13;
        csr_wr_en_o                      <= 1'b0;
        ecall_trap_id_o                  <= 1'b0;
        ebreak_trap_id_o                 <= 1'b0;
        sret_trap_id_o                   <= 1'b0;
        itlb_miss_id_o                   <= 1'b0;
        itlb_wr_en_id_o                  <= 1'b0;
        dtlb_wr_en_id_o                  <= 1'b0;
    end
    else if(!id_stage_stall)
    begin // If stall generated else where (Peripheral Etc, Don't insert NOP)
        rs1_data_id_o                   <= rs1_forwarded_value            ;
        rs2_data_id_o                   <= rs2_forwarded_value            ;
        imm_value_id_o                  <= imm_value                      ;
        load_store_forward_sel_id_o     <= load_store_forward_sel         ;
        reg_write_en_id_o               <= reg_write_en                   ;
        rs1_pc_imm_sel_id_o             <= rs1_pc_imm_sel                 ;
        rs2_imm_csr_sel_id_o 	          <= rs2_imm_csr_sel                ;
        is_branch_instr_id_o            <= is_branch_instr                ;
        is_store_instr_id_o             <= is_store_instr                 ;
        is_load_instr_id_o              <= is_load_instr                  ;
        wb_sel_id_o                     <= wb_sel                         ;
        alu_op_id_o                     <= alu_op                         ;
        pc_id_o                         <= pc_id_i                        ;
        rd_label_id_o                   <= rd_label                       ;
        rs1_label_id_o                  <= rs1_label                      ;
        rs2_label_id_o                  <= rs2_label                      ;
        funct3_id_o                     <= funct3                         ;
        unconditional_branch_id_o       <= unconditional_branch           ;
        btb_predicted_pc_id_o 		      <= btb_predicted_pc_id_i          ;
        branch_is_taken_prediction_id_o <= branch_is_taken_prediction_id_i;
        fetched_instruction_id_o        <= fetched_instruction_id_i       ;
        ex_unit_sel_o                   <= ex_unit_sel                    ;
        sb_id_o                         <= sb_id_reg                      ;
        csr_wr_en_o                     <= csr_wr_en                      ;
        csr_addr_id_o                   <= csr_addr                       ;
        csr_rd_value_id_o               <= csr_rd_value                   ;
        ecall_trap_id_o                 <= ecall_trap                     ;
        ebreak_trap_id_o                <= ebreak_trap                    ;
        sret_trap_id_o                  <= sret_trap                      ;
        itlb_miss_id_o                  <= itlb_miss_id_i                 ;
        itlb_wr_en_id_o                 <= itlb_wr_en                     ;
        dtlb_wr_en_id_o                 <= dtlb_wr_en                     ;
      end
  end

wire [8*RISCV_DISASM_STRLEN-1:0] disasm_str = riscv_disasm(fetched_instruction_id_i, pc_id_i);
`ifdef CORE_VERBOSITY
  function void id_trace_log(int file);
    $fwrite(file,"\n***********Instruction Decode Stage****************:");
    $fwrite(file,"\nTime, %1t, Instruction: %0s, Program Counter: 0x%8h, peripheral_stall_id_i: %b, mem_stage_stall_i: %b\n", $time, disasm_str,pc_id_i,peripheral_stall_id_i,mem_stage_stall_i);
    
    csr_u.csr_trace_log(file);
    $fwrite(file, "\nTime: %1t, rs1_latest, in0: 0x%h, in1: 0x%h, in2: 0x%h, in3: 0x%h, forwardA: %b, rs1_forwarded_value: 0x%h", $time,rs1_value,rd_value_ex_i,rd_value_mem_i,rd_value_wb_i,forwardA,rs1_forwarded_value);
    $fwrite(file, "\nTime: %1t, rs2_latest, in0: 0x%h, in1: 0x%h, in2: 0x%h, in3: 0x%h, forwardA: %b, rs2_forwarded_value: 0x%h", $time,rs2_value,rd_value_ex_i,rd_value_mem_i,rd_value_wb_i,forwardB,rs2_forwarded_value);
    // $fwrite(file,"\nTime, %1t, CSR: ", $time)
    // register_file_u.dump_register_file(file);
  endfunction
`endif

endmodule
