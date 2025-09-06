module l1_data_cache 
#(
    parameter ENTRIES        = 64,
    parameter WORDS_PER_LINE = 2,
    parameter ADDRESS_WIDTH  = 32,
    parameter DATA_WIDTH     = 32
)
(
    input              clk_i,
    input              rst_i,
    input      [31:0]  address_i,
    input      [31:0]  write_data_i,
    input              is_load_instr,
    input              is_store_instr,
    input      [2:0 ]  funct3_i,
    output reg [31:0]  read_data_o
);

`include "encodings.vh"

// Address field sizes
localparam INDEX_BITS    = $clog2(ENTRIES);
localparam WORD_OFF_BITS = $clog2(WORDS_PER_LINE);
localparam BYTE_OFF_BITS = 2; // byte offset in word
localparam TAG_SIZE      = ADDRESS_WIDTH - (INDEX_BITS + WORD_OFF_BITS + BYTE_OFF_BITS);

// Address decode
wire [BYTE_OFF_BITS-1:0]  byte_off   = address_i[BYTE_OFF_BITS-1:0];
wire [WORD_OFF_BITS-1:0]  word_off   = address_i[BYTE_OFF_BITS + WORD_OFF_BITS - 1 : BYTE_OFF_BITS];
wire [INDEX_BITS-1:0]     index_bits = address_i[BYTE_OFF_BITS + WORD_OFF_BITS + INDEX_BITS - 1 :
                                                 BYTE_OFF_BITS + WORD_OFF_BITS];
wire [TAG_SIZE-1:0]       tag        = address_i[ADDRESS_WIDTH-1 :
                                                 BYTE_OFF_BITS + WORD_OFF_BITS + INDEX_BITS];

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
      for (j=0; j<WORDS_PER_LINE; j=j+1) begin
        data_cache[i][j] <= {DATA_WIDTH{1'b0}};
      end
    end
    rd_word <= {DATA_WIDTH{1'b0}};
  end else begin
    // store path
    if (is_store_instr) begin
      valid_bit[index_bits] <= 1'b1;
      dirty_bit[index_bits] <= 1'b1;
      tag_arr[index_bits]   <= tag;

      case (funct3_i)
        `SB_FUNCT3: begin
          // write a single byte inside the word
          case (byte_off)
            2'd0: data_cache[index_bits][word_off][ 7: 0] <= write_data_i[7:0];
            2'd1: data_cache[index_bits][word_off][15: 8] <= write_data_i[7:0];
            2'd2: data_cache[index_bits][word_off][23:16] <= write_data_i[7:0];
            2'd3: data_cache[index_bits][word_off][31:24] <= write_data_i[7:0];
          endcase
        end
        `SH_FUNCT3: begin
          // write a halfword
          if (byte_off[1]==1'b0)
            data_cache[index_bits][word_off][15:0]  <= write_data_i[15:0];
          else
            data_cache[index_bits][word_off][31:16] <= write_data_i[15:0];
        end
        `SW_FUNCT3: begin
          // write full word
          data_cache[index_bits][word_off] <= write_data_i;
        end
        default: begin
          data_cache[index_bits][word_off] <= 32'hD8C7B6A5;
        end
      endcase
    end

    // load path (capture word)
    if (is_load_instr)
      rd_word <= data_cache[index_bits][word_off];
  end
end

// Format read_data_o according to funct3_i (sign/zero extend)
always @* begin
  case (funct3_i)
    `LB_FUNCT3: begin
      case (byte_off)
        2'd0: read_data_o = {{24{rd_word[ 7]}}, rd_word[ 7: 0]};
        2'd1: read_data_o = {{24{rd_word[15]}}, rd_word[15: 8]};
        2'd2: read_data_o = {{24{rd_word[23]}}, rd_word[23:16]};
        2'd3: read_data_o = {{24{rd_word[31]}}, rd_word[31:24]};
      endcase
    end
    `LBU_FUNCT3: begin
      case (byte_off)
        2'd0: read_data_o = {24'h0, rd_word[ 7: 0]};
        2'd1: read_data_o = {24'h0, rd_word[15: 8]};
        2'd2: read_data_o = {24'h0, rd_word[23:16]};
        2'd3: read_data_o = {24'h0, rd_word[31:24]};
      endcase
    end
    `LH_FUNCT3: begin
      if (byte_off[1]==1'b0)
        read_data_o = {{16{rd_word[15]}}, rd_word[15:0]};
      else
        read_data_o = {{16{rd_word[31]}}, rd_word[31:16]};
    end
    `LHU_FUNCT3: begin
      if (byte_off[1]==1'b0)
        read_data_o = {16'h0, rd_word[15:0]};
      else
        read_data_o = {16'h0, rd_word[31:16]};
    end
    default: begin // LW
      read_data_o = rd_word;
    end
  endcase
end

`ifdef CORE_VERBOSITY
  function void l1_data_cache_trace_log(int file);
    $fwrite(file, "\nTime: %1t L1 Data Cache, address: %b, word_off: %b, index_bits: %b, tag: %b, byte_off: %b ",$time,address_i,word_off,index_bits,tag,byte_off);
    // $fwrite(file, "\nTime: %1t L1 Data Cache, word_addr_dcache: %b",$time,word_addr_dcache);
    if(`CORE_VERBOSITY >= 500)begin
        l1_d_cache_entry_trace_log(file);
      end
  endfunction
  
  function void l1_d_cache_entry_trace_log(int file);
  integer idx, widx;
    $fwrite(file, "\n Index, V, D, Tag \t\t\t");
    for (widx = 0; widx < WORDS_PER_LINE; widx = widx + 1) begin
        // one fwrite per entry/word — you can fill in what you want printed
        $fwrite(file, "Word%1d \t \t", widx); // <-- fill this with desired info per entry/word
      end
    $fwrite(file,"\n");
    for (idx = 0; idx < ENTRIES; idx = idx + 1) begin  
       $fwrite(file, "%3d,    %1b, %1b, %x", idx, valid_bit[idx], dirty_bit[idx], tag_arr[idx]);
for (widx = 0; widx < WORDS_PER_LINE; widx = widx + 1)
  $fwrite(file, "\t0x%08h", data_cache[idx][widx]);
$fwrite(file, "\n");
    end
  endfunction
`endif 

endmodule
