`timescale 1ns/1ps


/*TODO: 
1- Trunc opcode from the immgen input
2- Refactor and Verify Forwarding Unit
3- What Happens if load then branch comes, and that branch is depending on the load value?
4- Forwarding Unit Won't Forward From Instructions That Writes value from PC (JAL, JALR), Move the WB sel to MEM Stage, pass result
6- unconditional branches wont work atm (Need to be tested!)
*/
module core(
    input clk_i, rst_i
);

//Instruction Fetch Stage Variables
wire [31:0] pc_incremented_if_o;
wire [31:0] fetched_instruction_if_o;
//--------------------------------------------


//Instruction Decode Stage Variable Declarations
wire [31:0] rs1_data_id_o, rs2_data_id_o;
wire [4:0] rd_label_id_o, rs1_label_id_o, rs2_label_id_o;
wire [31:0] imm_value_id_o;
wire load_stall_id_o, load_store_forward_sel_id_o;
wire reg_write_en_id_o, rs1_pc_sel_id_o, rs2_imm_sel_id_o;
wire is_branch_instr_id_o, is_store_instr_id_o, is_load_instr_id_o;
wire [1:0] wb_sel_id_o;
wire [3:0] alu_op_id_o;
wire [31:0] pc_id_o;
wire [2:0] funct3_id_o;
wire unconditional_branch_id_o;
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
//--------------------------------------------

//Instruction Memory Stage Variable Declarations
wire [31:0] alu_result_mem_o;
wire [31:0] load_value_mem_o;
wire [31:0] pc_mem_o;
wire [4:0] rd_label_mem_o;
wire reg_write_en_mem_o;
wire [1:0] wb_sel_mem_o;
wire is_load_mem_o;
//--------------------------------------------

//WriteBack Stage Variable Declarations
wire [31:0] rd_value_wb_mem_o;
wire reg_write_en_wb_o;
wire [31:0] alu_result_wb_o, load_data_wb_o, pc_wb_o;





instruction_fetch if_u(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .fetched_instruction_if_o(fetched_instruction_if_o),
    .pc_incremented_if_o(pc_incremented_if_o),

    //Inputs From  Instruction Decode Stage For Load Hazard
    .load_stall_if_i(load_stall_id_o),

    //Inputs From Execution Stage For Branching,
    .branching_i(branching_ex_o),
    .branching_address_i(branch_address_ex_o)

    
);


instruction_decode id_u(
    .clk_i(clk_i),
    .rst_i(rst_i),
    //Instruction Fetch Inputs
    .fetched_instruction_id_i(fetched_instruction_if_o),
    .pc_id_i(pc_incremented_if_o),

    //Register Related Outputs
    .rs1_data_id_o(rs1_data_id_o),
    .rs2_data_id_o(rs2_data_id_o),
    .rd_label_id_o(rd_label_id_o),
    .rs1_label_id_o(rs1_label_id_o),
    .rs2_label_id_o(rs2_label_id_o),

    //Immediate Value
    .imm_value_id_o(imm_value_id_o),

    //Hazard Detection Unit
    .load_stall_id_o(load_stall_id_o),
    .load_store_forward_sel_id_o(load_store_forward_sel_id_o),

    //Control Unit
    .reg_write_en_id_o(reg_write_en_id_o),
    .rs1_pc_sel_id_o(rs1_pc_sel_id_o),
    .rs2_imm_sel_id_o(rs2_imm_sel_id_o),
    .is_branch_instr_id_o(is_branch_instr_id_o),
    .is_store_instr_id_o(is_store_instr_id_o),
    .is_load_instr_id_o(is_load_instr_id_o),
    .wb_sel_id_o(wb_sel_id_o),
    .alu_op_id_o(alu_op_id_o),
    .unconditional_branch_id_o(unconditional_branch_id_o),

    //Program Counter
    .pc_id_o(pc_id_o),
    .funct3_id_o(funct3_id_o),


    //Inputs from Exeuction Stage
    .is_load_instruction_ex_i(is_load_instr_id_o),
    .rd_label_ex_i(rd_label_id_o),

    //Inputs From WriteBack Stage
    .reg_write_en_wb_i(reg_write_en_mem_o),
    .rd_label_wb_i(rd_label_mem_o),
    .rd_value_wb_i(rd_value_wb_mem_o),

    //Pipeline Control Signals
    .branching_id_i(branching_ex_o)
    
    );

    instruction_execution ex_u(
        .clk_i(clk_i),
        .rst_i(rst_i),
        
        //Inputs from Instruction Decode Stage
        .rs1_data_ex_i(rs1_data_id_o),
        .rs2_data_ex_i(rs2_data_id_o),
        .rd_label_ex_i(rd_label_id_o),
        .rs1_label_ex_i(rs1_label_id_o),
        .rs2_label_ex_i(rs2_label_id_o),
        .imm_value_ex_i(imm_value_id_o),
        .load_stall_ex_i(load_stall_id_o),
        .load_store_forward_sel_ex_i(load_store_forward_sel_id_o),
        .reg_write_en_ex_i(reg_write_en_id_o),
        .rs1_pc_sel_ex_i(rs1_pc_sel_id_o),
        .rs2_imm_sel_ex_i(rs2_imm_sel_id_o),
        .is_branch_instr_ex_i(is_branch_instr_id_o),
        .is_store_instr_ex_i(is_store_instr_id_o),
        .is_load_instr_ex_i(is_load_instr_id_o),
        .wb_sel_ex_i(wb_sel_id_o),
        .alu_op_ex_i(alu_op_id_o),
        .pc_ex_i(pc_id_o),
        .funct3_ex_i(funct3_id_o),
        .unconditional_branch_ex_i(unconditional_branch_id_o),

        //Outputs to Memory Stage
        .alu_result_ex_o(alu_result_ex_o),
        .load_store_forward_sel_ex_o(load_store_forward_sel_ex_o),
        .reg_write_en_ex_o(reg_write_en_ex_o),
        .is_load_instr_ex_o(is_load_instr_ex_o),
        .is_store_instr_ex_o(is_store_instr_ex_o),
        .rd_label_ex_o(rd_label_ex_o),
        .wb_sel_ex_o(wb_sel_ex_o),
        .pc_ex_o(pc_ex_o),
        .funct3_ex_o(funct3_ex_o),
        .latest_rs2_value_ex_o(latest_rs2_value_ex_o),

        //Inputs From Memory Stage
        .reg_write_en_mem_i(reg_write_en_ex_o),
        .rd_label_mem_i(rd_label_ex_o),
        .alu_result_mem_i(alu_result_ex_o),

        //Inputs From WriteBack Stage
        .reg_write_en_wb_i(reg_write_en_mem_o),
        .rd_label_wb_i(rd_label_mem_o),
        .is_load_instr_wb_i(is_load_mem_o),
        .alu_result_wb_i(alu_result_mem_o),
        .load_data_wb_i(load_value_mem_o),
        // Multi-Usage Output
        .branching_ex_o(branching_ex_o),
        .branch_address_ex_o(branch_address_ex_o)
    );


    instruction_memory_stage mem_u (
        .clk_i(clk_i),
        .rst_i(rst_i),
        
        //Inputs From Execution stage
        .alu_result_mem_i(alu_result_ex_o),
        .load_store_forward_sel_mem_i(load_store_forward_sel_ex_o),
        .reg_write_en_mem_i(reg_write_en_ex_o),
        .rd_label_mem_i(rd_label_ex_o),
        .wb_sel_mem_i(wb_sel_ex_o),
        .pc_mem_i(pc_ex_o),
        .funct3_mem_i(funct3_ex_o),
        .is_store_mem_i(is_store_instr_ex_o),
        .is_load_mem_i(is_load_instr_ex_o),
        .latest_rs2_value_mem_i(latest_rs2_value_ex_o),

        //Outputs To WriteBack Stage
        .alu_result_mem_o(alu_result_mem_o),
        .load_value_mem_o(load_value_mem_o),
        .pc_mem_o(pc_mem_o),
        .rd_label_mem_o(rd_label_mem_o),
        .reg_write_en_mem_o(reg_write_en_mem_o),
        .wb_sel_mem_o(wb_sel_mem_o),
        .is_load_mem_o(is_load_mem_o),
        
        //Inputs From Writeback Stage    
        .load_value_wb_i(load_value_mem_o)
    );


    mux_4x1 #(
        .DATA_WIDTH(32)
    ) mux_wb_u(
        .sel_i(wb_sel_mem_o),
        .in0_i(alu_result_mem_o),
        .in1_i(load_value_mem_o),
        .in2_i(pc_mem_o),
        .in3_i(32'hA9A9A9A9),
        .out_o(rd_value_wb_mem_o)
    );

endmodule