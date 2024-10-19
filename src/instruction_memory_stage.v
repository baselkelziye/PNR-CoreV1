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


module instruction_memory_stage(
    input clk_i, rst_i,
    
    //Inputs from Execution stage
    input [31:0] alu_result_mem_i,
    
    input load_store_forward_sel_mem_i, reg_write_en_mem_i,
    input [4:0] rd_label_mem_i,
    input [1:0] wb_sel_mem_i,
    input [31:0] pc_mem_i,
    input [2:0] funct3_mem_i,
    input is_store_mem_i, is_load_mem_i,
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
    input wire [31:0] load_value_wb_i
    );


    //Load-Store Forwarding
    wire [31:0] forwarded_store_value;
    assign forwarded_store_value = (load_store_forward_sel_mem_i) ? load_value_wb_i : latest_rs2_value_mem_i;


    wire [31:0] loaded_data;

    datum_cache datum_cache_u(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .address_i(alu_result_mem_i),
        .write_data_i(forwarded_store_value),
        .is_load_instr(is_load_mem_i),
        .is_store_instr(is_store_mem_i),
        .funct3_i(funct3_mem_i),
        .read_data_o(loaded_data)
    );


    mux_4x1 #(
        .DATA_WIDTH(32)
    ) rd_value_selector_u(
        .in0_i(alu_result_mem_i),
        .in1_i(loaded_data),
        .in2_i(pc_mem_i),
        .in3_i(32'hA9A9A9A9),
        .sel_i(wb_sel_mem_i),
        .out_o(rd_value_mem_wo)
    );

    always @(posedge clk_i, posedge rst_i) begin
        if(rst_i) begin
            load_value_mem_o <= 32'b0;
            rd_label_mem_o <= 5'b0;
            reg_write_en_mem_o <= 1'b0;
            wb_sel_mem_o <= 2'b0;
            is_load_mem_o <= 1'b0;
            rd_value_mem_ro <= 32'b0;
        end else begin
            load_value_mem_o <= loaded_data;
            rd_label_mem_o <= rd_label_mem_i;
            reg_write_en_mem_o <= reg_write_en_mem_i;
            wb_sel_mem_o <= wb_sel_mem_i;
            is_load_mem_o <= is_load_mem_i;
            rd_value_mem_ro <= rd_value_mem_wo;
        end
    end

endmodule
