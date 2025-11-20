module l1_icache_array
#(
    parameter I_ENTRIES = 32,
    parameter I_WORDS_PER_LINE = 4,
    parameter INSTRUCTION_WIDTH = 32,
    localparam I_INDEX_BITS = $clog2(I_ENTRIES),
    localparam I_WORD_OFF_BITS = $clog2(I_WORDS_PER_LINE),
    localparam I_TAG_SIZE = INSTRUCTION_WIDTH - (I_INDEX_BITS + I_WORD_OFF_BITS + 2)
)
(
    input clk_i,
    input rst_i,

    input [I_INDEX_BITS-1    :0]                        icache_index_bits_i,
    input [I_WORD_OFF_BITS-1 :0]                        icache_word_off_i  ,
    input                                               icache_line_fill_i,
    input [I_WORDS_PER_LINE-1:0][INSTRUCTION_WIDTH-1:0] icache_line_fill_data_i,

    output [I_TAG_SIZE-1:0] icache_indexed_tag_o,
    output                  icache_indexed_valid_o
);

reg                         icache_valid_bit [0:I_ENTRIES-1];
reg [I_TAG_SIZE-1       :0] icache_tag_arr[0:I_ENTRIES];
reg [INSTRUCTION_WIDTH-1:0] icache_line [0:I_ENTRIES-1][0:I_WORDS_PER_LINE-1];

integer i,j,y;
always @(posedge clk_i, posedge rst_i) begin
    if(rst_i) begin
        for(i = 0; i < I_ENTRIES; i = i +1) begin
            icache_valid_bit[i] = 1'b0;
            icache_tag_arr[i] = '0;
            for(j = 0; j < I_WORDS_PER_LINE; j = j+1) begin
                icache_line[i][j] = '0;
            end
        end
    end else begin //RST Ends
        if(icache_line_fill_i) begin
            icache_valid_bit[icache_index_bits_i] <= 1'b1;
            for(y = 0; y < I_WORDS_PER_LINE; y = y+1) begin
                icache_line[icache_index_bits_i][y] <= icache_line_fill_data_i[y];
            end
        end
    end
end

assign icache_indexed_tag_o   = icache_tag_arr[icache_index_bits_i];
assign icache_indexed_valid_o = icache_tag_arr[icache_index_bits_i];

endmodule