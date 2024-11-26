`timescale 1ns / 1ps
module uart #(
    parameter data_bit_size = 8,
              stop_bit_size = 16,
              BAUD_COUNTER  = 325,
              BAUD_SIZE  = 9,
              FIFO_W        = 2
) (
    input wire clk, reset,
    input wire rd_uart, wr_uart, rx,
    input wire [7:0] w_data,
    output wire tx_full, rx_empty, tx,
    output wire tx_empty, rx_full,
    output wire [7:0] rd_data
);


wire bd_tick, rx_done_tick, tx_done_tick;
wire  tx_fifo_not_empty;
wire [7:0] tx_fifo_out, rx_data_out;

baud_generator #(
    .BAUD_COUNTER(BAUD_COUNTER), .BAUD_SIZE(BAUD_SIZE)
) baud_generator_u
(
    .clk(clk), .reset(reset), .tick(bd_tick)
);

uart_rx #(
    .data_bit_size(data_bit_size), .stop_bit_size(stop_bit_size)
)
uart_receiver(
    .clk(clk), .reset(reset), .rx(rx), .bd_tick(bd_tick), .rx_done(rx_done_tick), .r_data(rx_data_out)
);


fifo #(
    .B(data_bit_size), .W(FIFO_W)
)
fifo_rx_unit(
    .clk(clk), .reset(reset), .rd(rd_uart), .wr(rx_done_tick), .w_data(rx_data_out), .empty(rx_empty), .full(rx_full), .r_data(rd_data)
);

// fifo #(
//     .B(data_bit_size), .W(FIFO_W)
// )
// fifo_rx_unit(
//     .clk(clk), .reset(reset), .rd(tx_done_tick), .wr(wr_uart), .w_data(w_data), .empty(tx_empty), .full(tx_full), .r_data(tx_fifo_out)
// );



fifo #(
    .B(data_bit_size), .W(FIFO_W)
)
fifo_tx_unit(
    .clk(clk), .reset(reset), .rd(tx_done_tick), .wr(wr_uart), .w_data(w_data), .empty(tx_empty), .full(tx_full), .r_data(tx_fifo_out)
);

uart_tx #(
    .data_bit_size(data_bit_size), .stop_bit_size(stop_bit_size)
)
uart_transmitter(
    .clk(clk), .reset(reset), .tx_start(tx_fifo_not_empty), .bd_tick(bd_tick), .din(tx_fifo_out), .tx_done(tx_done_tick), .tx(tx)
);

assign tx_fifo_not_empty =  ~tx_empty;

endmodule