module l1_data_cache 
#(
    parameter ENTRIES = 64,
    parameter WAYS    = 1 , //This is not used for direct mapped caches
    parameter WORD_PER_LINE = 2,
    localparam ADDRESS_WIDTH = 32,
    localparam DATA_WIDTH    = 32
)
(
    input              clk_i         ,
    input              rst_i         ,
    input      [31:0]  address_i     ,
    input      [31:0]  write_data_i  ,
    input              is_load_instr ,
    input              is_store_instr,
    input      [2:0 ]  funct3_i      ,
    output reg [31:0]  read_data_o
);

`include "encodings.vh"

localparam INDEX_BITS_SIZE  = $clog2(ENTRIES);
localparam WORD_OFFSET_SIZE = $clog2(WORD_PER_LINE);
localparam TAG_SIZE = ADDRESS_WIDTH - (INDEX_BITS_SIZE + WORD_OFFSET_SIZE + 2);
localparam DIRTY_BIT_SIZE = 1;
localparam VALID_BIT_SIZE = 1;
localparam CACHE_ENTRY_SIZE = VALID_BIT_SIZE + DIRTY_BIT_SIZE + TAG_SIZE + (WORD_PER_LINE*DATA_WIDTH); 


wire [INDEX_BITS_SIZE-1:0] index_bits;
wire [WORD_OFFSET_SIZE-1:0] word_offset;
wire [TAG_SIZE - 1:0] tag;
//valid_dirty_tag_wordX
(* verilator public_flat_rw *)
reg  [CACHE_ENTRY_SIZE- 1:0 ] data_cache[0:ENTRIES-1]; 
wire [CACHE_ENTRY_SIZE -1:0 ] dcache_entry;
wire [CACHE_ENTRY_SIZE -1:0 ] word_addr_dcache;
//Input's Word_offset, Index and Tag Information
assign word_offset = address_i[WORD_OFFSET_SIZE+1:2]; // Lower 2 bits is ignored, We have aligned accesses only.
assign index_bits  = address_i[INDEX_BITS_SIZE + WORD_OFFSET_SIZE + 1 :WORD_OFFSET_SIZE + 1 + 1];
assign tag         = address_i[ADDRESS_WIDTH-1:INDEX_BITS_SIZE + WORD_OFFSET_SIZE  + 1 + 1];

//The LSB pointer for the word_offset in data cache entry, required for writing.
assign word_addr_dcache = VALID_BIT_SIZE + DIRTY_BIT_SIZE + TAG_SIZE + (unsigned'(word_offset+1) * DATA_WIDTH);


//Cache Write
integer i;
always @(posedge clk_i, posedge rst_i) begin
    if(rst_i) begin
        for ( i = 0; i < ENTRIES; i = i +1 ) begin
            data_cache[i] = '0;
        end
    end else begin
            if(is_store_instr) begin
                case (funct3_i)
                    `SB_FUNCT3: data_cache[word_addr_dcache +: 8 ] <= write_data_i[7:0];
                    `SH_FUNCT3: data_cache[word_addr_dcache +: 16] <= write_data_i[15:0];
                    `SW_FUNCT3: data_cache[word_addr_dcache +: 32] <= write_data_i[31:0];
                    default   : data_cache[word_addr_dcache +: 32] <= 32'hD8C7B6A5;
                endcase
            end
    end
end


`ifdef CORE_VERBOSITY
  function void l1_data_cache_trace_log(int file);
    $fwrite(file, "\nTime: %1t L1 Data Cache, address: %b, word_offset: %b, index_bits: %b, tag: %b ",$time,address_i,word_offset,index_bits,tag);
    $fwrite(file, "\nTime: %1t L1 Data Cache, word_addr_dcache: %b",$time,word_addr_dcache);
  endfunction
`endif 

  

endmodule