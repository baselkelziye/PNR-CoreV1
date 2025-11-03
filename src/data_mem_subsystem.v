`timescale 1ns / 1ps
module data_mem_subsystem #(
    parameter ENTRIES        = 32,
    parameter WORDS_PER_LINE = 4,
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
    output             dcache_stall_o,
    output     [31:0]  read_data_o
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
//Signals From dcache array -> dcache controller
wire indexed_dirty_bit,indexed_valid_bit;
wire [TAG_SIZE-1:0] indexed_tag;
wire [TAG_SIZE-1:0] dcache_cntrl_tag_o;

//Signals From dcache controller -> dcache array
wire dcache_cntrl_valid_bit_o, dcache_cntrl_dirty_bit_o,dcache_cntrl_update_entry_o;

//dcache controller -> RAM
wire [ADDRESS_WIDTH-1-2:0] ram_wr_addr;
//RAM-> dcache array tag
wire [ADDRESS_WIDTH-1-2:0] ram_rd_addr;

wire start_ram_write,start_ram_read;

//Ram -> dcache controller
wire ram_wr_done, ram_rd_done;

//dcache Array => RAM
wire [WORDS_PER_LINE-1:0][DATA_WIDTH-1:0] dcache_array_dline_wr;
wire [WORDS_PER_LINE-1:0][DATA_WIDTH-1:0] dcache_array_dline_rd;
wire [3:0] [7:0] read_word_darray;
wire [7:0] read_byte;
wire [15:0] read_half;
wire [ADDRESS_WIDTH-1:0] read_word;

//Store Buffer signals
wire sb_drain, sb_is_full;

assign ram_wr_addr = {indexed_tag,index_bits,{WORD_OFF_BITS{1'b0}}}; // We write from Array Controller to RAM
assign ram_rd_addr = {address_i[ADDRESS_WIDTH-1:WORD_OFF_BITS + BYTE_OFF_BITS],{WORD_OFF_BITS{1'b0}}};
assign {read_word_darray[3],read_word_darray[2],read_word_darray[1],read_word_darray[0]} = dcache_array_dline_wr[word_off];

assign read_byte = read_word_darray[byte_off]; // Read 1 Byte
assign read_half = {read_word_darray[{byte_off[1],1'b1}] , read_word_darray[{byte_off[1],1'b0}]};
assign read_word = dcache_array_dline_wr[word_off];

assign read_data_o = (funct3_i == `LB_FUNCT3)  ? {{24{read_byte[7]}},read_byte}    :
                     (funct3_i == `LH_FUNCT3)  ? {{16{read_half[15]}}, read_half}  :
                     (funct3_i == `LW_FUNCT3)  ? read_word                         :
                     (funct3_i == `LBU_FUNCT3) ? {24'b0, read_byte}                :
                     (funct3_i == `LHU_FUNCT3) ? {16'b0, read_half[15:0]}   :
                                                                        32'hA1A1A1A1;

l1_dcache_array #(
    .ENTRIES        (   ENTRIES         ),
    .WORDS_PER_LINE (   WORDS_PER_LINE  ),
    .ADDRESS_WIDTH  (   ADDRESS_WIDTH   ),
    .DATA_WIDTH     (   DATA_WIDTH      )
) l1_dcache_array_u
(
    .clk_i              (   clk_i                           ),
    .rst_i              (   rst_i                           ),
    .write_data_i       (   write_data_i                    ),
    .funct3_i           (   funct3_i                        ),
    .index_bits_i       (   index_bits                      ),
    .byte_off_i         (   byte_off                        ),
    .word_off_i         (   word_off                        ),
    // .update_entry_i     (   dcache_cntrl_update_entry_o     ),
    .update_entry_cpu_i (   dcache_cntrl_update_entry_cpu   ),
    .update_entry_mem_i (   dcache_cntrl_update_entry_mem   ),
    .dirty_bit_i        (   dcache_cntrl_dirty_bit_o        ),
    .valid_bit_i        (   dcache_cntrl_valid_bit_o        ),
    .tag_i              (   dcache_cntrl_tag_o              ),
    .ram_rd_data_i      (   dcache_array_dline_rd           ),
    .indexed_dirty_bit_o(   indexed_dirty_bit               ),
    .indexed_valid_bit_o(   indexed_valid_bit               ),
    .indexed_tag_o      (   indexed_tag                     ),
    .ram_wr_data_o      (   dcache_array_dline_wr           )
);

logic dcache_cntrl_update_entry_cpu,dcache_cntrl_update_entry_mem;

l1_dcache_controller l1_dcache_controller_u
(
    .clk_i                           (   clk_i                          ),
    .rst_i                           (   rst_i                          ),
    .is_load_instr_i                 (   is_load_instr                  ),
    .is_store_instr_i                (   is_store_instr                 ),
    //The tag of the current address_i
    .tag_i                           (   tag                            ),
    //Indexed Valid, Dirty and Tags from dcache_array
    .indexed_tag_i                   (   indexed_tag                    ),
    .indexed_dirty_bit_i             (   indexed_dirty_bit              ),
    .indexed_valid_bit_i             (   indexed_valid_bit              ),
    .indexed_data_raw_i              (   dcache_array_dline_wr          ),
    .dcache_stall_o                  (   dcache_stall_o                 ),
    .dcache_cntrl_valid_bit_o        (   dcache_cntrl_valid_bit_o       ),
    .dcache_cntrl_dirty_bit_o        (   dcache_cntrl_dirty_bit_o       ),
    .dcache_cntrl_tag_o              (   dcache_cntrl_tag_o             ),
    // .dcache_cntrl_update_entry_o     (   dcache_cntrl_update_entry_o    ),
    .dcache_cntrl_update_entry_cpu_o (   dcache_cntrl_update_entry_cpu  ),
    .dcache_cntrl_update_entry_mem_o (   dcache_cntrl_update_entry_mem  ),
    //Outputs to RAM memory 
    .start_ram_write_o               (   start_ram_write                ),
    .start_ram_read_o                (   start_ram_read                 ),
    //Inputs from RAM Memory 
    .ram_wr_done_i                   (   ram_wr_done                    ),
    .ram_rd_done_i                   (   ram_rd_done                    )
);


DATA_RAM #(
    .WORDS_PER_LINE (   WORDS_PER_LINE  ),
    .ADDRESS_WIDTH  (   ADDRESS_WIDTH   ),
    .DATA_WIDTH     (   DATA_WIDTH      )
)
DATA_RAM_u(
    .clk_i              (   clk_i                   ),
    .rst_i              (   rst_i                   ),
    .wr_data_i          (   dcache_array_dline_wr   ),
    .rd_data_addr_i     (   ram_rd_addr             ),
    .wr_data_addr_i     (   ram_wr_addr             ),
    .start_ram_write_i  (   start_ram_write         ),
    .start_ram_read_i   (   start_ram_read          ),
    .rd_data_o          (   dcache_array_dline_rd   ),
    .ram_wr_done_o      (   ram_wr_done             ),
    .ram_rd_done_o      (   ram_rd_done             )
    
);

store_buffer store_buffer_u(
    .clk_i              (   clk_i           ),
    .rst_i              (   rst_i           ),
    .is_store_instr_i   (   is_store_instr  ),
    .write_data_i       (   write_data_i    ),
    .wr_addr_i          (   address_i       ),
    .funct3_i           (   funct3_i        ),
    .sb_is_full_o       (   sb_is_full      ),
    .drain_sb_o         (   sb_drain        )
);

`ifdef CORE_VERBOSITY


function void data_mem_subsystem_trace_log(int file);
// $fwrite(file, "\nTime: %1t L1 Data Cache, address: %b, word_off: %b, index_bits: %b, tag_i: %b, byte_off: %b ",$time,address_i,word_off,index_bits,tag_i,byte_off);
// $fwrite(file, "\nTime: %1t L1 Data Cache, word_addr_dcache: %b",$time,word_addr_dcache);
if(`CORE_VERBOSITY >= 500)begin
    l1_dcache_controller_u.dcache_controller_trace_log(file);
    // l1_dcache_array_u.l1_dcache_array_trace_log(file);
    store_buffer_u.store_buffer_trace_log(file);
    DATA_RAM_u.DATA_RAM_trace_log(file);
    $fwrite(file,"\nTime: %1t Data Subsystem, read_word_darray[3]: %h, read_word_darray[2]: %h, read_word_darray[1]: %h, read_word_darray[0]: %h,  ", $time,read_word_darray[3],read_word_darray[2],read_word_darray[1],read_word_darray[0]);
    $fwrite(file,"\nTime: %1t , byte_off: %b,  read_byte: %h, read_half: %h, read_word: %h, dcache_array_dline_wr[word_off]: %h", $time,byte_off,read_byte,read_half,read_word, dcache_array_dline_wr[word_off]);
    end

endfunction

`endif

endmodule