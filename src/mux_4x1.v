`timescale 1ns / 1ps

module mux_4x1
#(
    parameter DATA_WIDTH = 8    // Width of each input
)
(
    input wire [DATA_WIDTH-1:0] in0_i,  // Input 0
    input wire [DATA_WIDTH-1:0] in1_i,  // Input 1
    input wire [DATA_WIDTH-1:0] in2_i,  // Input 2
    input wire [DATA_WIDTH-1:0] in3_i,  // Input 3
    input wire [1:0] sel_i,          // Selection line
    output reg [DATA_WIDTH-1:0] out_o   // Output
);

always @* begin
    case (sel_i)
        2'b00: out_o = in0_i;  // Select input 0
        2'b01: out_o = in1_i;  // Select input 1
        2'b10: out_o = in2_i;  // Select input 2
        2'b11: out_o = in3_i;  // Select input 3
        default: out_o = {DATA_WIDTH{1'b0}}; // Default output to all zeros
    endcase
end

endmodule
