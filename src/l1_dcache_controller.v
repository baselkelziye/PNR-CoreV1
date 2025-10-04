`timescale 1ns / 1ps
module l1_dcache_controller 
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
    input              is_load_instr_i,
    input              is_store_instr_i,

    input [TAG_SIZE-1:0] tag_i,
    input [TAG_SIZE-1:0] indexed_tag_i,
    input                indexed_dirty_bit_i,
    input                indexed_valid_bit_i,

    output               dcache_stall_o,
    output               dcache_cntrl_valid_bit_o,
    output               dcache_cntrl_dirty_bit_o,
    output [TAG_SIZE-1:0] dcache_cntrl_tag_o,
    output               dcache_cntrl_update_entry_o,

    //Outputs to RAM DATA
    output               start_ram_write_o,
    output               start_ram_read_o,

    //Inputs from RAM DATA
    input ram_wr_done_i,
    input ram_rd_done_i
);

`include "encodings.vh"

localparam [1:0] IDLE        = 2'b00,
                 COMPARE_TAG = 2'b01,
                 WRITE_BACK  = 2'b10,
                 ALLOCATE    = 2'b11;

reg [1:0] state_reg, state_next;
wire valid_cache_access;
reg cache_access_stall_reg, cache_access_stall_next;
reg cache_hit;
reg dcache_cntrl_valid_bit, dcache_cntrl_dirty_bit;
reg [TAG_SIZE-1:0]  dcache_cntrl_tag;
reg dcache_cntrl_update_entry;
reg start_ram_wr_reg, start_ram_wr_next;
reg start_ram_rd_reg, start_ram_rd_next;
always @(posedge clk_i) begin
    if(rst_i) begin
        state_reg <= IDLE;
        cache_access_stall_reg <= 1'b0;
        start_ram_wr_reg       <= 1'b0;
        start_ram_rd_reg       <= 1'b0;
    end else begin
        state_reg <= state_next;
        cache_access_stall_reg <= cache_access_stall_next;
        start_ram_wr_reg       <= start_ram_wr_next;
        start_ram_rd_reg       <= start_ram_rd_next;
    end
end

assign valid_cache_access = is_load_instr_i | is_store_instr_i;


always @(*) begin
    state_next = state_reg;
    cache_access_stall_next = cache_access_stall_reg;
    cache_hit = 1'b0;
    dcache_cntrl_valid_bit = 1'b0;
    dcache_cntrl_dirty_bit = 1'b0;
    dcache_cntrl_tag       = '0;
    dcache_cntrl_update_entry = 1'b0;
    start_ram_rd_next = start_ram_rd_reg;
    start_ram_wr_next = start_ram_wr_reg;
    case (state_reg)
        IDLE: begin // If we have valid cache access, Stall processor
            if(valid_cache_access) begin
                state_next = COMPARE_TAG;
                cache_access_stall_next = 1'b1;
            end
        end
        COMPARE_TAG: begin
            cache_hit = (tag_i == indexed_tag_i) & indexed_valid_bit_i; //If indexed valid bit = 1 and we have tag match
            if(cache_hit) begin
                if(is_store_instr_i) begin // If we have hit and write, we just overwrite.
                    dcache_cntrl_valid_bit = 1'b1;
                    dcache_cntrl_dirty_bit = 1'b1;
                    dcache_cntrl_tag       = tag_i;
                    dcache_cntrl_update_entry = 1'b1;
                    cache_access_stall_next = 1'b0;
                    state_next             = IDLE;
                end else begin //Here we read directly the values.
                    cache_access_stall_next = 1'b0;
                    state_next             = IDLE;
                end
            end else begin // Cache Miss.
                if(is_store_instr_i) begin //Store miss, If dirty=1, Write back to not lose the data
                    if(indexed_dirty_bit_i) begin
                        state_next = WRITE_BACK;
                        start_ram_wr_next = 1'b1;
                    end else begin //If dirty is not set, Write to cache
                        dcache_cntrl_valid_bit = 1'b1;
                        dcache_cntrl_dirty_bit = 1'b1;
                        dcache_cntrl_tag       = tag_i;
                        dcache_cntrl_update_entry = 1'b1;
                        cache_access_stall_next = 1'b0;
                        state_next             = IDLE;
                end
                end else begin //Load Miss, Go to Allocate
                    if(indexed_dirty_bit_i) begin //Here we have Dirty Bit, We need to Write to RAM before Allocating
                        start_ram_wr_next = 1'b1;
                        state_next = WRITE_BACK;
                    end else begin
                        start_ram_rd_next = 1'b1;
                        state_next = ALLOCATE;
                    end
                end
            end
        end
        WRITE_BACK: begin
            start_ram_wr_next = 1'b0;
            if(~start_ram_wr_reg & ram_wr_done_i) begin //Ram Access is Done
                start_ram_rd_next = 1'b1;
                state_next      = ALLOCATE; //Go Allocate the requested block from RAM
            end 
        end
        ALLOCATE : begin
            start_ram_rd_next = 1'b0;
            if(~start_ram_rd_reg & ram_rd_done_i) begin //When we Allocate Data, We should Update our Tag Array
                dcache_cntrl_valid_bit    = 1'b1;
                dcache_cntrl_dirty_bit    = 1'b0;// Fresh Data
                dcache_cntrl_tag          = tag_i;
                dcache_cntrl_update_entry = 1'b1;
                state_next                = COMPARE_TAG; //After we Allocate, Go and try to find.
            end 
        end
        default: begin
            state_next = IDLE;
            cache_access_stall_next = 1'b0;
        end
    endcase
end

assign dcache_stall_o = cache_access_stall_next; //If we capture reg, stall will fire in next cycle and we will miss the mem instruction in mem stage
assign dcache_cntrl_valid_bit_o = dcache_cntrl_valid_bit;
assign dcache_cntrl_dirty_bit_o = dcache_cntrl_dirty_bit;
assign dcache_cntrl_tag_o       = dcache_cntrl_tag;
assign dcache_cntrl_update_entry_o = dcache_cntrl_update_entry;
assign start_ram_write_o = start_ram_wr_reg;
assign start_ram_read_o  = start_ram_rd_reg;

`ifdef CORE_VERBOSITY

reg [127:0] state_str_reg; // enough width to hold your longest string

always @* begin
  case (state_reg)
    IDLE:        state_str_reg = "IDLE";
    COMPARE_TAG: state_str_reg = "COMPARE_TAG";
    WRITE_BACK:  state_str_reg = "WRITE_BACK";
    ALLOCATE:    state_str_reg = "ALLOCATE";
    default:     state_str_reg = "UNKNOWN";
  endcase
end

reg [127:0] state_str_next; // enough width to hold your longest string

always @* begin
  case (state_next)
    IDLE:        state_str_next = "IDLE";
    COMPARE_TAG: state_str_next = "COMPARE_TAG";
    WRITE_BACK:  state_str_next = "WRITE_BACK";
    ALLOCATE:    state_str_next = "ALLOCATE";
    default:     state_str_next = "UNKNOWN";
  endcase
end

function void dcache_controller_trace_log(int file);
$fwrite(file,"\nTime: %1t, Cache Controller, state_reg: %0s, state_next: %0s, dcache_stall_o: %b, tag_i: 0x%x, indexed_tag_i: 0x%x, indexed_valid_bit: %b, indexed_dirty_bit: %b",$time, state_str_reg,state_str_next,dcache_stall_o,tag_i,indexed_tag_i,indexed_valid_bit_i,indexed_dirty_bit_i);
$fwrite(file,"\nTime: %1t, Cache Controller, cache_hit: %b, is_load_instr_i: %b, is_store_instr_i: %b, ram_wr_done_i: %b, ram_rd_done_i: %b, start_ram_write_o: %b, start_ram_read_o: %b ",$time, cache_hit,is_load_instr_i,is_store_instr_i,ram_wr_done_i,ram_rd_done_i,start_ram_write_o,start_ram_read_o);
endfunction
`endif 

endmodule