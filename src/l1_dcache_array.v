`timescale 1ns / 1ps
module l1_dcache_array 
#(
    parameter ENTRIES        = 64,
    parameter WORDS_PER_LINE = 2,
    parameter ADDRESS_WIDTH  = 32,
    parameter DATA_WIDTH     = 32,
    localparam INDEX_BITS = $clog2(ENTRIES),
    localparam WORD_OFF_BITS = $clog2(WORDS_PER_LINE),
    localparam BYTE_OFF_BITS = 2,
    localparam TAG_SIZE      = ADDRESS_WIDTH - (INDEX_BITS + WORD_OFF_BITS + BYTE_OFF_BITS)
)
(
    input              clk_i,
    input              rst_i,

    input      [31:0]  write_data_i,
    input      [2:0 ]  funct3_i,
    
    //Control Inputs
    input [INDEX_BITS-1:0] index_bits_i,
    input [BYTE_OFF_BITS-1:0] byte_off_i,
    input [WORD_OFF_BITS-1:0] word_off_i,
    input update_entry_i,
    // Value Inputs
    input dirty_bit_i,
    input valid_bit_i,
    input [TAG_SIZE-1:0] tag_i,
    
    //outputs to cache controller
    output indexed_dirty_bit_o,
    output indexed_valid_bit_o,
    output [TAG_SIZE-1:0] indexed_tag_o,

    output [DATA_WIDTH-1:0] ram_wr_data_o[0:WORDS_PER_LINE-1]
);

`include "encodings.vh"

// Address field sizes



// Storage arrays
reg                       valid_bit [0:ENTRIES-1];
reg                       dirty_bit [0:ENTRIES-1];
reg [TAG_SIZE-1:0]        tag_arr   [0:ENTRIES-1];
reg [DATA_WIDTH-1:0]      data_cache [0:ENTRIES-1][0:WORDS_PER_LINE-1]; // the data words

// Internal read latch
reg [DATA_WIDTH-1:0] rd_word;

// Reset
integer i,j;
always @(posedge clk_i or posedge rst_i) begin
  if (rst_i) begin
    for (i=0; i<ENTRIES; i=i+1) begin
      valid_bit[i] <= 1'b0;
      dirty_bit[i] <= 1'b0;
      tag_arr[i]   <= {TAG_SIZE{1'b0}};
    end
  end else begin
    // store path
    if (update_entry_i) begin
      valid_bit[index_bits_i] <= valid_bit_i;
      dirty_bit[index_bits_i] <= dirty_bit_i;
      tag_arr[index_bits_i]   <= tag_i;

      case (funct3_i)
        `SB_FUNCT3: begin
          // write a single byte inside the word
          case (byte_off_i)
            2'd0: data_cache[index_bits_i][word_off_i][ 7: 0] <= write_data_i[7:0];
            2'd1: data_cache[index_bits_i][word_off_i][15: 8] <= write_data_i[7:0];
            2'd2: data_cache[index_bits_i][word_off_i][23:16] <= write_data_i[7:0];
            2'd3: data_cache[index_bits_i][word_off_i][31:24] <= write_data_i[7:0];
          endcase
        end
        `SH_FUNCT3: begin
          // write a halfword
          if (byte_off_i[1]==1'b0)
            data_cache[index_bits_i][word_off_i][15:0]  <= write_data_i[15:0];
          else
            data_cache[index_bits_i][word_off_i][31:16] <= write_data_i[15:0];
        end
        `SW_FUNCT3: begin
          // write full word
          data_cache[index_bits_i][word_off_i] <= write_data_i;
        end
        default: begin
          data_cache[index_bits_i][word_off_i] <= 32'hD8C7B6A5;
        end
      endcase
    end

  end
end

assign indexed_dirty_bit_o = dirty_bit[index_bits_i];
assign indexed_valid_bit_o = valid_bit[index_bits_i];
assign indexed_tag_o       = tag_arr[index_bits_i];

for(genvar i=0; i < WORDS_PER_LINE; i = i+1) begin :g_darray_2_ram_data_assignment
  assign ram_wr_data_o[i] = data_cache[index_bits_i][i];
end

`ifdef CORE_VERBOSITY
  
  function void l1_dcache_array_trace_log(int file);
  integer idx, widx;
    $fwrite(file, "\nTime: %1t, Cache Array, index_bits: %d,  indexed_valid: %b, indexed_dirty: %b, indexed_tag: %x, update_entry_i: %b, valid_bit_i: %b, dirty_bit_i: %b, tag_i: %x, write_data_i: %x",$time, index_bits_i,indexed_valid_bit_o,indexed_dirty_bit_o,indexed_tag_o, update_entry_i,valid_bit_i,dirty_bit_i,tag_i,write_data_i);
    if(`CORE_VERBOSITY >= 600) begin
      
    
    $fwrite(file, "\n Index, V, D, tag_i \t\t");
    for (widx = 0; widx < WORDS_PER_LINE; widx = widx + 1) begin
        $fwrite(file, "Word%1d \t \t", widx);
      end
    $fwrite(file,"\n");
    for (idx = 0; idx < ENTRIES; idx = idx + 1) begin  
       $fwrite(file, "%3d,    %1b, %1b, 0x%x", idx, valid_bit[idx], dirty_bit[idx], tag_arr[idx]);
    for (widx = 0; widx < WORDS_PER_LINE; widx = widx + 1)
        $fwrite(file, "\t0x%08h", data_cache[idx][widx]);
    $fwrite(file, "\n");
    end
  end
  endfunction
`endif 

endmodule
