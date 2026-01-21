`timescale 1ns / 1ps
module l1_dcache_array 
#(
    parameter ENTRIES        = 32,
    parameter D_WORDS_PER_LINE = 4,
    parameter ADDRESS_WIDTH  = 32,
    parameter DATA_WIDTH     = 32,
    localparam INDEX_BITS = $clog2(ENTRIES),
    localparam WORD_OFF_BITS = $clog2(D_WORDS_PER_LINE),
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
    // input update_entry_i,
    // Value Inputs
    input dirty_bit_i,
    input valid_bit_i,
    input [TAG_SIZE-1:0] tag_i,
    input [DATA_WIDTH-1:0] ram_rd_data_i [0:D_WORDS_PER_LINE-1],

    input update_entry_cpu_i,
    input update_entry_mem_i,
    
    //outputs to cache controller
    output indexed_dirty_bit_o,
    output indexed_valid_bit_o,
    output [TAG_SIZE-1:0] indexed_tag_o,

    output [DATA_WIDTH-1:0] ram_wr_data_o[0:D_WORDS_PER_LINE-1]
);

`include "encodings.vh"

// Address field sizes



// Storage arrays
(* verilator public_flat_rw *)
reg                       valid_bit [0:ENTRIES-1];
reg                       dirty_bit [0:ENTRIES-1];
reg [TAG_SIZE-1:0]        tag_arr   [0:ENTRIES-1];
reg [DATA_WIDTH-1:0]      data_cache [0:ENTRIES-1][0:D_WORDS_PER_LINE-1]; // the data words

// Internal read latch
reg [DATA_WIDTH-1:0] rd_word;
wire update_entry;
assign update_entry = update_entry_cpu_i | update_entry_mem_i;
// Reset
integer i,j,y;
always @(posedge clk_i) begin
  if (rst_i) begin
    for (i=0; i<ENTRIES; i=i+1) begin
      valid_bit[i] <= 1'b0;
      dirty_bit[i] <= 1'b0;
      tag_arr[i]   <= {TAG_SIZE{1'b0}};
      for(j=0; j < D_WORDS_PER_LINE; j=j+1) begin
        data_cache[i][j] <= '0;  
      end
    end
  end else begin
    // store path
    if (update_entry) begin
      valid_bit[index_bits_i] <= valid_bit_i;
      dirty_bit[index_bits_i] <= dirty_bit_i;
      tag_arr[index_bits_i]   <= tag_i;
      if(update_entry_cpu_i) begin
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
      end else begin // write from mem
          for(y = 0; y < D_WORDS_PER_LINE; y=y+1) begin
            data_cache[index_bits_i][y] <= ram_rd_data_i[y];
          end
      end
    end

  end
end

assign indexed_dirty_bit_o = dirty_bit[index_bits_i];
assign indexed_valid_bit_o = valid_bit[index_bits_i];
assign indexed_tag_o       = tag_arr[index_bits_i];

for(genvar i=0; i < D_WORDS_PER_LINE; i = i+1) begin :g_darray_2_ram_data_assignment
  assign ram_wr_data_o[i] = data_cache[index_bits_i][i];
end

`ifdef CORE_VERBOSITY
  
  function void l1_dcache_array_trace_log(int file);
  integer idx, widx;
  integer i;
  logic [INDEX_BITS-1:0] index_bits_iterator;
  logic [WORD_OFF_BITS-1:0] BLOCK_ITERATOR;
  logic [WORD_OFF_BITS-1:0] WORD_OFF;

    $fwrite(file, "\nTime: %1t, Cache Array, index_bits: %d,  indexed_valid: %b, indexed_dirty: %b, indexed_tag: %x, update_entry_cpu_i: %b, update_entry_mem_i: %b, valid_bit_i: %b, dirty_bit_i: %b, tag_i: %x, write_data_i: %x",$time, index_bits_i,indexed_valid_bit_o,indexed_dirty_bit_o,indexed_tag_o, update_entry_cpu_i, update_entry_mem_i,valid_bit_i,dirty_bit_i,tag_i,write_data_i);
    if(`CORE_VERBOSITY >= 600) begin
      
    
    $fwrite(file, "\n Index, V, D, tag_i \t\t");
    for (widx = 0; widx < D_WORDS_PER_LINE; widx = widx + 1) begin
        $fwrite(file, "Word%1d \t \t", widx);
      end
      for (widx = 0; widx < D_WORDS_PER_LINE; widx = widx + 1) begin
        $fwrite(file, "PA%1d \t \t", widx);
      end
    $fwrite(file,"\n");
    for (idx = 0; idx < ENTRIES; idx = idx + 1) begin  
      index_bits_iterator = idx;
       $fwrite(file, "%3d,    %1b, %1b, 0x%x", idx, valid_bit[idx], dirty_bit[idx], tag_arr[idx]);
    for (widx = 0; widx < D_WORDS_PER_LINE; widx = widx + 1)
        $fwrite(file, "\t0x%08h", data_cache[idx][widx]);
    for (widx = 0; widx < D_WORDS_PER_LINE; widx = widx + 1) begin 
        WORD_OFF = widx;
        $fwrite(file, "\t0x%08h", {tag_arr[index_bits_iterator], index_bits_iterator,{WORD_OFF_BITS{1'b0}},WORD_OFF});
    end
    $fwrite(file, "\n");
    end
  end
  endfunction
`endif 

endmodule
