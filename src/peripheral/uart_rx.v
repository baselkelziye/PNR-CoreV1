`timescale 1ns / 1ps
module uart_rx
#(parameter data_bit_size = 8,
            stop_bit_size = 16)
(
    input clk, reset,
    input rx,
    input bd_tick,
    output reg rx_done,
    output [7:0] r_data
);



localparam [1:0] 
    idle  = 2'b00,
    start = 2'b01,
    data  = 2'b10,
    stop  = 2'b11;

    reg [3:0] over_sampling_counter_reg, over_sampling_counter_next;
    reg [2:0] read_bit_counter_reg, read_bit_counter_next;
    reg [7:0] read_data_reg, read_data_next;
    reg [2:0] state_reg, state_next;

    always @(posedge clk, posedge reset)
    begin
        if(reset) begin
            over_sampling_counter_reg <= 4'b0;
            read_bit_counter_reg         <= 3'b0;
            state_reg                 <= idle;
            read_data_reg             <= 8'hAA;
        end else begin
            over_sampling_counter_reg <= over_sampling_counter_next;
            read_bit_counter_reg         <= read_bit_counter_next;
            state_reg                 <= state_next;
            read_data_reg             <= read_data_next;
        end
    end


    always @* begin
        state_next =state_reg;
        rx_done = 1'b0;
        over_sampling_counter_next = over_sampling_counter_reg;
        read_bit_counter_next = read_bit_counter_reg;
        read_data_next = read_data_reg;
        case(state_reg)
            idle:
            begin
                if(~rx)
                    state_next = start;
                    over_sampling_counter_next = 0;
            end
            start:
            begin
                if(bd_tick) begin
                    if(over_sampling_counter_reg == 7) begin
                        state_next = data;
                        read_bit_counter_next = 0;
                        over_sampling_counter_next = 0;
                    end else begin
                        over_sampling_counter_next = over_sampling_counter_reg + 1;
                    end
                end               
            end
            data:
            begin
                if(bd_tick) begin
                    if(over_sampling_counter_reg == 15)
                    begin
                        read_data_next = {rx, read_data_reg[7:1]};
                        over_sampling_counter_next = 0;
                        if(read_bit_counter_reg == (data_bit_size - 1))
                            state_next = stop;
                        else
                            read_bit_counter_next = read_bit_counter_reg  + 1;                          
                    end else
                        over_sampling_counter_next = over_sampling_counter_reg + 1;
                end 
            end
            stop:
            begin
                if(bd_tick) begin
                    if(over_sampling_counter_reg == stop_bit_size -1) begin
                        rx_done = 1'b1;
                        state_next = idle;
                    end else begin
                        over_sampling_counter_next = over_sampling_counter_reg + 1;
                    end

                end
            end
                
        endcase
    end

    assign r_data = read_data_reg;

endmodule