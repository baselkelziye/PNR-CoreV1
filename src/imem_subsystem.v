
`define I_BYTE_OFF I_BYTE_OFF_BITS-1:0
`define I_WORD_OFF I_BYTE_OFF_BITS + I_WORD_OFF_BITS - 1 : I_BYTE_OFF_BITS
`define I_INDEX I_BYTE_OFF_BITS + I_WORD_OFF_BITS + I_INDEX_BITS - 1 : I_BYTE_OFF_BITS + I_WORD_OFF_BITS
`define I_TAG INSTRUCTION_WIDTH-1 : I_BYTE_OFF_BITS + I_WORD_OFF_BITS + I_INDEX_BITS

module imem_subsystem #(
    parameter I_ENTRIES = 32,
    parameter I_WORDS_PER_LINE = 4,
    parameter INSTRUCTION_WIDTH = 32
)
(
    input clk_i,
    input rst_i, 
    input [31:0] icache_pc_i,

    output icache_fill_stall_o,

    //Inputs from RAM
    input icache_fill_done_i,
    input [INSTRUCTION_WIDTH-1:0] icache_fill_line_data_i[0:I_WORDS_PER_LINE-1], 

    //Arbiter signals
    input icache_req_ready_i, //Arbiter grants transcation
    output icache_req_valid_o, //icache request is valid
    output icache_data_ready_o, // icache is ready to receive
    //RAM signals
    input icache_resp_valid_i, //Ram finished operation
    input ram_response_id_i, //Id of the operation (to not mix dcache)
    //Outputs to RAM
    output icache_fill_req_o,
    input branch_ex_i,

    //itlb signals
    output itlb_miss_o,
    input [1:0] execution_mode_i,

    output [INSTRUCTION_WIDTH-1:0] icache_fetched_instr_o
);

localparam I_INDEX_BITS    = $clog2(I_ENTRIES);
localparam I_WORD_OFF_BITS = $clog2(I_WORDS_PER_LINE);
localparam I_BYTE_OFF_BITS = 2;
localparam I_TAG_SIZE = INSTRUCTION_WIDTH - (I_INDEX_BITS + I_WORD_OFF_BITS + I_BYTE_OFF_BITS);
localparam ITLB_ENTRIES = 32;
localparam DATA_WIDTH =32;
wire [I_INDEX_BITS-1   :0] icache_index_bits;
wire [I_WORD_OFF_BITS-1:0] icache_word_off_bits;
wire [I_TAG_SIZE-1     :0] icache_tag_bits, icache_indexed_tag;
wire [INSTRUCTION_WIDTH-1:0] icache_indexed_line[0:I_WORDS_PER_LINE-1];

wire icache_hit, icache_indexed_valid;

assign icache_index_bits    = icache_pc_i[`I_INDEX];
assign icache_word_off_bits = icache_pc_i[`I_WORD_OFF];
assign icache_tag_bits      = icache_pc_i[`I_TAG];

assign icache_hit = (icache_tag_bits == icache_indexed_tag) & icache_indexed_valid;
assign icache_fetched_instr_o = icache_indexed_line[icache_word_off_bits];
// icache controller -> icache tag array 
wire icache_fill_line_o;


l1_icache_array #(
    .I_ENTRIES          (   I_ENTRIES           ),
    .I_WORDS_PER_LINE   (   I_WORDS_PER_LINE    ),
    .INSTRUCTION_WIDTH  (   INSTRUCTION_WIDTH   )
)
l1_icache_array_u
(
    .clk_i                      (   clk_i                   ),
    .rst_i                      (   rst_i                   ),
    .icache_index_bits_i        (   icache_index_bits       ),
    .icache_tag_bits_i          (   icache_tag_bits         ),
    .icache_word_off_i          (   icache_word_off_bits    ),
    .icache_fill_line_data_i    (   icache_fill_line_data_i ),
    .icache_line_fill_i         (   icache_fill_line_o      ),

    //The line pointed by current PC (to compare hit/miss)
    .icache_indexed_tag_o   (   icache_indexed_tag      ),
    .icache_indexed_valid_o (   icache_indexed_valid    ),
    .icache_indexed_line_o  (   icache_indexed_line     )
);

l1_icache_controller l1_icache_controller_u(
    .clk_i                  (   clk_i                 ),
    .rst_i                  (   rst_i                 ),
    .icache_fill_stall_o    (   icache_fill_stall_o   ),
    .icache_fill_line_o     (   icache_fill_line_o    ),
    // Request to Arbiter
    .icache_req_valid_o     (   icache_req_valid_o    ), //I have active request
    .icache_req_ready_i     (   icache_req_ready_i    ), //Arbiter Grants access
    //Response from RAM
    .icache_resp_valid_i       (   icache_resp_valid_i      ), //Data Finishes
    .ram_response_id_i      (   ram_response_id_i     ), //Icache reqeust
    .icache_data_ready_o    (   icache_data_ready_o   ), //We are ready to accept new data
    .icache_hit_i           (   icache_hit            ),
    .branch_ex_i            (   branch_ex_i           )
);
wire itlb_miss;
wire [31:0] itlb_data;

itlb #(
    .ITLB_ENTRIES(ITLB_ENTRIES),
    .DATA_WIDTH(DATA_WIDTH)
) itlb_u(
    .clk_i(clk_i),
    .rst_i(rst_i),
    //Write Signals
    .itlb_wr_en_i(1'b0),
    .rs1_i('1),
    .rs2_i('1),
    .execution_mode_i(execution_mode_i),
    //Lookup signals
    .pc_i(icache_pc_i),
    .itlb_miss_o(itlb_miss),
    .itlb_data_o(itlb_data)
);

assign itlb_miss_o = itlb_miss;

`ifdef CORE_VERBOSITY

function void imem_subsystem_trace_log(int file);
$fwrite(file, "\nTime: %0t, IMEM: pc: %h, stall: %b, fill_done: %b, fill_req: %b, index: %h, word_off: %h, tag: %h, hit: %b, instr: %h", 
            $time, 
            icache_pc_i, 
            icache_fill_stall_o, 
            icache_fill_done_i, 
            icache_fill_req_o, 
            icache_index_bits, 
            icache_word_off_bits, 
            icache_tag_bits, 
            icache_hit, 
            icache_fetched_instr_o
        );
endfunction

`endif 

endmodule