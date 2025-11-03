module store_buffer(
    input clk_i,
    input rst_i,

    input is_store_instr_i,
    input [31:0] wr_addr_i,
    input [31:0] write_data_i,
    input [2:0] funct3_i,

    output sb_is_full_o,
    output drain_sb_o

);


/*
My Store Buffer Entry Holds
Address = 32 Bits
Data = 32 Bits
Valid Bytes (for LB, LW support)
Valid Bit

Valid Bit - Address - Data - Valid Byte
[1]       -    32   -  32   - 4 
*/

localparam ADDRESS_WIDTH = 32;
localparam DATA_WIDTH = 32;
localparam VALID_BYTES = 3;
localparam VALID_BIT = 1;
localparam SB_DEPTH = 2; //Its sized 2**SB_DEPTH
localparam SB_ENTRY_SIZE = ADDRESS_WIDTH + DATA_WIDTH + VALID_BYTES + VALID_BIT;


wire [SB_ENTRY_SIZE-1:0] sb_entry_wr, sb_entry_rd;
wire sb_drain;
wire sb_empty, sb_full;

assign sb_entry_wr = {1'b1, wr_addr_i, write_data_i,funct3_i};

fifo #(
    .B(SB_ENTRY_SIZE),
    .W(SB_DEPTH)
) sb_fifo_u (
    .clk      ( clk_i           ),
    .reset    ( rst_i           ),
    .rd       ( sb_drain        ),
    .wr       ( is_store_instr_i),
    .w_data   ( sb_entry_wr     ),
    .empty    ( sb_empty        ),
    .full     ( sb_full         ),
    .r_data   ( sb_entry_rd     )
);

`ifdef CORE_VERBOSITY

function store_buffer_trace_log(int file);
integer i;
$fwrite(file, "\nTime: %1t, Store Buffer, sb_drain: %b, sb_empty: %b, sb_full: %b, write_data_i: %h, wr_addr_i: %h\n", $time, sb_drain,sb_empty,sb_full,write_data_i,wr_addr_i);
for(i = 0; i <  (2**SB_DEPTH); i = i+1) begin
    $fwrite(file, "SB[%1d]: valid_bit: %b, address: 0x%h, data: 0x%h valid_bytes: %b\n", i, sb_fifo_u.array_reg[i][SB_ENTRY_SIZE-1],sb_fifo_u.array_reg[i][ADDRESS_WIDTH+VALID_BYTES+DATA_WIDTH-1:VALID_BYTES+DATA_WIDTH],sb_fifo_u.array_reg[i][VALID_BYTES+DATA_WIDTH-1:VALID_BYTES], sb_fifo_u.array_reg[i][VALID_BYTES-1:0]);
end
endfunction

`endif

endmodule