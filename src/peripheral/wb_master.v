module wb_master(
    //outputs To WB Slave
    output o_wb_cyc,
    output o_wb_stb,
    output o_wb_we,
    output [31:0] o_wb_addr,
    output [31:0] o_wb_data,

    //inputs From WB Slave
    input i_wb_stall,
    input i_wb_ack,
    input [31:0] i_wb_data,

    //inputs from CPU
    input is_load_instr_i,
    input is_store_instr_i,
    input [31:0] mmio_address, wr_data_i,
    output peripheral_stall_o
);


wire is_peripheral_access;

assign is_peripheral_access = (is_load_instr_i || is_store_instr_i) && (mmio_address[31:28] == 4'b0010);

assign o_wb_cyc = is_peripheral_access & ~i_wb_ack;
assign o_wb_stb = o_wb_cyc;

assign o_wb_we = is_peripheral_access && is_store_instr_i;
assign o_wb_addr = mmio_address;
assign o_wb_data = wr_data_i;

assign peripheral_stall_o = i_wb_stall | (is_peripheral_access & ~i_wb_ack);
//assign peripheral_stall_o = 1'b0;

endmodule