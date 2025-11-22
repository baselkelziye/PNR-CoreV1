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
    input [I_TAG_SIZE-1      :0]                        icache_tag_bits_i,
    input [I_WORD_OFF_BITS-1 :0]                        icache_word_off_i  ,
    input                                               icache_line_fill_i,
    input [I_WORDS_PER_LINE-1:0][INSTRUCTION_WIDTH-1:0] icache_fill_line_data_i,

    output [I_TAG_SIZE-1:0] icache_indexed_tag_o,
    output                  icache_indexed_valid_o,
    output [INSTRUCTION_WIDTH-1:0] icache_indexed_line_o[0:I_WORDS_PER_LINE-1],
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
            icache_tag_arr[icache_index_bits_i] <= icache_tag_bits_i;
            for(y = 0; y < I_WORDS_PER_LINE; y = y+1) begin
                icache_line[icache_index_bits_i][y] <= icache_fill_line_data_i[y];
            end
        end
    end
end

assign icache_indexed_tag_o   = icache_tag_arr[icache_index_bits_i];
assign icache_indexed_valid_o = icache_valid_bit[icache_index_bits_i];
assign icache_indexed_line_o  = icache_line[icache_index_bits_i];


`ifdef CORE_VERBOSITY
  
  function void l1_icache_array_trace_log(int file);
    integer idx, widx;
    integer i;
    logic [I_INDEX_BITS-1:0] index_bits_iterator;
    logic [I_WORD_OFF_BITS-1:0] WORD_OFF;

    $fwrite(file, "\nTime: %1t, ICache Array, index_bits: %d, indexed_valid: %b, indexed_tag: %x, line_fill_i: %b", 
            $time, icache_index_bits_i, icache_indexed_valid_o, icache_indexed_tag_o, icache_line_fill_i);
    
    if(`CORE_VERBOSITY >= 600) begin
      $fwrite(file, "\n Index, V, tag \t\t");
      for (widx = 0; widx < I_WORDS_PER_LINE; widx = widx + 1) begin
        $fwrite(file, "Word%1d \t \t", widx);
      end
      for (widx = 0; widx < I_WORDS_PER_LINE; widx = widx + 1) begin
        $fwrite(file, "PA%1d \t \t", widx);
      end
      $fwrite(file,"\n");
      
      for (idx = 0; idx < I_ENTRIES; idx = idx + 1) begin  
        index_bits_iterator = idx;
        $fwrite(file, "%3d,    %1b, 0x%x", idx, icache_valid_bit[idx], icache_tag_arr[idx]);
        
        for (widx = 0; widx < I_WORDS_PER_LINE; widx = widx + 1)
          $fwrite(file, "\t0x%08h", icache_line[idx][widx]);
          
        for (widx = 0; widx < I_WORDS_PER_LINE; widx = widx + 1) begin 
          WORD_OFF = widx;
          $fwrite(file, "\t0x%08h", {icache_tag_arr[idx], index_bits_iterator, {I_WORD_OFF_BITS{1'b0}}, WORD_OFF});
        end
        $fwrite(file, "\n");
      end
    end
  endfunction
  
`endif 
endmodule