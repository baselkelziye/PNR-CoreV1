`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2024 10:38:13 AM
// Design Name: 
// Module Name: mux_2x1
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


`timescale 1ns / 1ps

module mux_2x1
#(
    parameter DATA_WIDTH = 8    // Width of each input
)
(
    input wire [DATA_WIDTH-1:0] in0_i,  // Input 0
    input wire [DATA_WIDTH-1:0] in1_i,  // Input 1
    input wire sel_i,                // Selection line
    output reg [DATA_WIDTH-1:0] out_o   // Output
);

always @* begin
    case (sel_i)
        1'b0: out_o = in0_i;  // Select input 0
        1'b1: out_o = in1_i;  // Select input 1
        default: out_o = {DATA_WIDTH{1'b0}}; // Default output to all zeros
    endcase
end

endmodule
