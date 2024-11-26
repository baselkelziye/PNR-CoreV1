`timescale 1ns / 1ps
module uart_tx
#(parameter data_bit_size = 8,
            stop_bit_size = 16)
(
    input wire clk, reset,
    input tx_start, bd_tick,
    input wire [7:0] din,
    
    output wire tx,
    output reg  tx_done
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
    reg tx_reg, tx_next;


    always @(posedge clk, posedge reset) begin
        if(reset) begin
            state_reg <= idle;
            read_data_reg <= 0;
            over_sampling_counter_reg <= 0;
            read_bit_counter_reg <= 0;
            tx_reg <= 1'b1;
        end else begin
            state_reg <= state_next;
            read_data_reg <= read_data_next;
            over_sampling_counter_reg <= over_sampling_counter_next;
            read_bit_counter_reg <= read_bit_counter_next;
            tx_reg <= tx_next;
        end
    end


    always @(*) begin
        state_next = state_reg;
        tx_done = 1'b0;
        over_sampling_counter_next = over_sampling_counter_reg;
        read_bit_counter_next = read_bit_counter_reg;
        read_data_next = read_data_reg;
        tx_next = tx_reg;
        case(state_reg)
            idle:       
            begin
             tx_next = 1'b1; // Idle'da seviye 1 olmali.
                if(tx_start) begin
                    state_next = start;
                    read_data_next = din;
                    over_sampling_counter_next = 0;
                end
            end

            start:
            begin
                tx_next = 1'b0;
                if(bd_tick) begin
                    if(over_sampling_counter_reg == 15) begin
                        over_sampling_counter_next = 0;
                        state_next = data;
                        read_bit_counter_next = 0;
                    end else 
                        over_sampling_counter_next = over_sampling_counter_reg  + 1;
                end
            end
            data:
            begin
                tx_next = read_data_reg[0]; 
                if(bd_tick) begin
                    if(over_sampling_counter_reg == 15) begin
                        over_sampling_counter_next = 0;
                        read_data_next = read_data_reg >> 1;
                        if(read_bit_counter_reg == data_bit_size -1) begin
                            state_next = stop;
                        end else begin
                            read_bit_counter_next = read_bit_counter_reg + 1;
                        end
                    end else begin
                        over_sampling_counter_next = over_sampling_counter_reg + 1;
                    end
                end
            end

            stop:
            begin
                tx_next = 1'b1;
                if(bd_tick) begin
                    if(over_sampling_counter_reg == stop_bit_size - 1) begin
                        tx_done = 1'b1;
                        state_next = idle;
                    end else begin
                        over_sampling_counter_next = over_sampling_counter_reg + 1;
                    end
                end
            end
        endcase 
    end

    assign tx = tx_reg;


endmodule