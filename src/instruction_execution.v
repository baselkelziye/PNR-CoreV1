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
        input reg_write_en_ex_i, rs1_pc_sel_ex_i, rs2_imm_sel_ex_i,
        input is_branch_instr_ex_i, is_store_instr_ex_i, is_load_instr_ex_i,
        input [1:0] wb_sel_ex_i,
        input [3:0] alu_op_ex_i,
        input [31:0] pc_ex_i,
        input [2:0] funct3_ex_i,
        input unconditional_branch_ex_i,

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
        output wire [31:0] branch_address_ex_o
    );

//Branch Jump Unit
wire branch_jump_unit_o;

// assign branching
assign branching_ex_o = (branch_jump_unit_o & is_branch_instr_ex_i) | unconditional_branch_ex_i;
assign branch_address_ex_o = alu_result;

//ALU Signals
wire [31:0] alu_result;
wire [31:0] alu1_input, alu2_input;

//Fowarding Unit Signals
wire [1:0] forwardA, forwardB;
wire [31:0] rs1_latest_value, rs2_latest_value;


forwarding_unit forwarding_unit_u(
    .rd_label_ex_mem_o(rd_label_mem_i),
    .rd_label_mem_wb_o(rd_label_wb_i),
    .rs1_label_id_ex_o(rs1_label_ex_i),
    .rs2_label_id_ex_o(rs2_label_ex_i),
    .reg_wb_en_ex_mem_o(reg_write_en_mem_i),
    .reg_wb_en_mem_wb_o(reg_write_en_wb_i),
    .forwardA(forwardA),
    .forwardB(forwardB)
);

//Forwarding The Register Signals
mux_4x1 #(
    .DATA_WIDTH(32)
) rs1_latest_value_selector(
    .in0_i(rs1_data_ex_i),
    .in1_i(rd_value_wb_i),
    .in2_i(rd_value_mem_i),
    .in3_i(32'hA1A1A1A1),
    .sel_i(forwardA),
    .out_o(rs1_latest_value)
);


mux_4x1 #(
    .DATA_WIDTH(32)
) rs2_latest_value_selector(
    .in0_i(rs2_data_ex_i),
    .in1_i(rd_value_wb_i),
    .in2_i(rd_value_mem_i),
    .in3_i(32'hA2A2A2A2),
    .sel_i(forwardB),
    .out_o(rs2_latest_value)
);


branch_jump branch_jump_u(
    .in1_i(rs1_latest_value),
    .in2_i(rs2_latest_value),
    .funct3_i(funct3_ex_i),
    .PC_sel_o(branch_jump_unit_o)
);



//Logic Is Forwarded, Need To select Imm Value Or PC

mux_2x1 #(
    .DATA_WIDTH(32)
) alu1_selector(
    .in0_i(rs1_latest_value),
    .in1_i(pc_ex_i),
    .sel_i(rs1_pc_sel_ex_i),
    .out_o(alu1_input)
);

mux_2x1 #(
    .DATA_WIDTH(32)
) alu2_selector(
    .in0_i(rs2_latest_value),
    .in1_i(imm_value_ex_i),
    .sel_i(rs2_imm_sel_ex_i),
    .out_o(alu2_input)
);





ALU ALU_u(
    .alu1_i(alu1_input),
    .alu2_i(alu2_input),
    .alu_op_i(alu_op_ex_i),
    .result_o(alu_result)
);


always @(posedge clk_i, rst_i) begin
    if(rst_i) begin
        alu_result_ex_o <= 32'h0;
        load_store_forward_sel_ex_o <= 1'b0;
        reg_write_en_ex_o <= 1'b0;
        is_load_instr_ex_o <= 1'b0;
        rd_label_ex_o <= 5'b0;
        wb_sel_ex_o <= 3'b0;
        pc_ex_o 	<= 32'b0;
        funct3_ex_o <= 3'b0;
        is_store_instr_ex_o <= 1'b0;
        latest_rs2_value_ex_o <= 32'h0;
    end else begin
        alu_result_ex_o <= alu_result;
        load_store_forward_sel_ex_o <= load_store_forward_sel_ex_i;
        reg_write_en_ex_o <= reg_write_en_ex_i;
        is_load_instr_ex_o <= is_load_instr_ex_i;
        rd_label_ex_o <= rd_label_ex_i;
        wb_sel_ex_o <= wb_sel_ex_i;
        pc_ex_o     <= pc_ex_i;
        funct3_ex_o <= funct3_ex_i;
        is_store_instr_ex_o <= is_store_instr_ex_i;
        latest_rs2_value_ex_o <= rs2_latest_value;

    end
end

endmodule
