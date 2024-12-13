`timescale 1ns / 1ps
/*
A wish Bone Slave UART Interface
Baud Rate is Fixed At: 19200
Data Bits can be configured
Stop Bits can be configured
No Parity Supported


*/

module wbs_uart(
    input i_clk, i_rst,
//Wishbone Signals
    input i_wb_cyc,
    input i_wb_stb,
    input i_wb_we,
    input [31:0] i_wb_addr,
    input [31:0] i_wb_data,
    output reg o_wb_ack,
    output o_wb_stall,
    output reg [31:0] o_wb_data
);

localparam [31:0] 
    uart_ctrl     = 32'h20000000,
    uart_status   = 32'h20000004,
    uart_rdata    = 32'h20000008,
    uart_wdata    = 32'h2000000C;

reg [31:0]  uart_ctrl_reg;
wire [31:0] uart_status_reg;
wire  [7:0] uart_rdata_reg;
reg [7:0] uart_wdata_reg;
wire tx_full, tx_empty, rx_full, rx_empty;
reg initiate_tx_transaction, initiate_rx_transaction;

assign uart_status_reg = {24'b0,rx_empty, rx_full, tx_empty, tx_full};

wire [7:0] tmp_rd_data;
assign tmp_rd_data = 8'hCC;

//Write Block
always @(posedge i_clk, posedge i_rst) begin
    
    if( (i_wb_stb) && (i_wb_we) && (!o_wb_stall))//Transaction Request, Write Enable, No Stall => We can Write
        case(i_wb_addr)
        uart_ctrl: uart_ctrl_reg <= i_wb_data;
        uart_status:begin end //We can't write to status register
        uart_rdata:begin end //We can't write to rdata register
        uart_wdata:begin uart_wdata_reg <= i_wb_data[7:0]; initiate_tx_transaction <= 1;end //Because we write to FIFO
        default: begin initiate_tx_transaction <= 0; end
        endcase
    else
        initiate_tx_transaction <= 0;
    end


//Read Block
always @(posedge i_clk) begin
    if(i_wb_stb && !i_wb_we && !o_wb_stall) //Transaction Request, Read Enable, No Stall => We can Read
        case(i_wb_addr)
        uart_ctrl: o_wb_data   <=  uart_ctrl_reg;
        uart_status: o_wb_data <= uart_status_reg;
        uart_rdata: begin 
            if(~rx_empty) begin 
                initiate_rx_transaction <= 1; //becasue we read from FIFO
                o_wb_data  <= {24'b0, tmp_rd_data};
            end
            else begin
                initiate_rx_transaction <= 0;
                o_wb_data <= 32'h000000CC;
            end
        end
            uart_wdata: begin end
        default: begin
            o_wb_data     <= 32'h00000000;
            initiate_rx_transaction <= 0;
            end
            endcase
    else
        initiate_rx_transaction <= 0;
end


//Latch ack
always @(posedge i_clk, posedge i_rst)begin
    if(i_rst)
        o_wb_ack <= 1'b0;
    else
        o_wb_ack <= ((i_wb_stb) && (!o_wb_stall)); //Transaction Request, No Stall => We can Acknowledge
end

//Since we R/W To fifo we can issue a transaction at a time and we don't need to stall
assign o_wb_stall = 0;

uart uart_unit(
    .clk(i_clk),
    .reset(i_rst),
    .rd_uart(initiate_rx_transaction),
    .wr_uart(initiate_tx_transaction),
    .rx(rx),
    .w_data(uart_wdata_reg),
    .tx_full(tx_full),
    .tx_empty(tx_empty),
    .rx_full(rx_full),
    .rx_empty(rx_empty), 
    .rd_data(uart_rdata_reg),
    .tx(tx)
);


endmodule