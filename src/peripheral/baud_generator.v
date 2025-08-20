`timescale 1ns / 1ps
module baud_generator
#(
    parameter BAUD_COUNTER = 100,
    BAUD_SIZE = 10
)
(
    input wire clk, reset,
    output tick
);


reg  [BAUD_SIZE -1 : 0] n_reg;
wire [BAUD_SIZE-1 : 0] n_next;


always @(posedge clk, posedge reset)
begin
    if(reset) begin
        n_reg <= 0;
    end else begin
        n_reg <= n_next;
    end
end

assign n_next = (n_reg == BAUD_COUNTER - 1) ? 0: n_reg + 1;
assign tick   = (n_reg == BAUD_COUNTER - 1) ? 1'b1 : 1'b0;


endmodule