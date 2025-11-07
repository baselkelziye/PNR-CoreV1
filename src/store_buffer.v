module store_buffer
#(
    parameter ADDRESS_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter VALID_BYTES = 3,
    parameter  SB_DEPTH = 2,
    parameter SB_ID_SIZE = 8,
    parameter  SB_ENTRY_SIZE = ADDRESS_WIDTH + DATA_WIDTH + VALID_BYTES + 1 + SB_ID_SIZE,
    localparam VALID_BIT = 1
)
(
    input clk_i,
    input rst_i,

    input is_store_instr_i,
    input is_load_instr_i,
    input [31:0] wr_addr_i,
    input [31:0] write_data_i,
    input [2:0] funct3_i,
    input cache_access_is_done_i,
    input [SB_ID_SIZE-1:0] sb_id_i,

    output [SB_ENTRY_SIZE-1:0]  sb_entry_rd_o,
    output                      sb_stall_o,
    output                      drain_sb_o,
    //Start a write from SB to Cache
    output                      sb_cache_wr_o,
    output                      sb_load_hit_o,
    output [DATA_WIDTH-1:0]     sb_forwarded_value_o

);


/*
My Store Buffer Entry Holds
Address = 32 Bits
Data = 32 Bits
Valid Bytes (for LB, LW support)
Valid Bit

Valid Bit - Address - Data - Valid Byte
[1]       -    32   -  32   - 3 
*/


localparam [1:0] SB_IDLE  = 2'b00,
                 SB_DRAIN = 2'b01,
                 SB_FULL  = 2'b10;

wire [SB_ENTRY_SIZE-1:0] sb_entry_wr, sb_entry_rd;
reg sb_drain_reg, sb_drain_next;
reg sb_cache_wr_reg, sb_cache_wr_next;
wire sb_empty, sb_full;
wire sb_wr_en, sb_rd_en;

// wire [1:0] sb_state_next;
reg  [1:0] sb_state_reg,sb_state_next;

always @(posedge clk_i, posedge rst_i) begin
    if(rst_i) begin
        sb_state_reg    <= 2'b0;
        sb_drain_reg    <= 1'b0;
        sb_cache_wr_reg <= 1'b0;
    end else begin
        sb_state_reg    <= sb_state_next;
        sb_drain_reg    <= sb_drain_next;
        sb_cache_wr_reg <= sb_cache_wr_next;
    end
end


always @(*) begin
    sb_state_next    = sb_state_reg;
    sb_drain_next    = sb_drain_reg;
    sb_cache_wr_next = sb_cache_wr_reg;
    case (sb_state_reg)
        SB_IDLE: begin
            if(/*sb_full & is_store_instr_i*/ ~sb_empty) begin // If SB is full, And we Have a Store
                sb_state_next = SB_DRAIN;
                sb_cache_wr_next = 1'b1;
                sb_drain_next    = 1'b1;
            end
        end 
        SB_DRAIN: begin //I should make a Handshake here for each Cache Transaction
            sb_cache_wr_next = 1'b0;
            if(~sb_cache_wr_reg & sb_drain_reg & cache_access_is_done_i) begin
                sb_drain_next = 1'b0;
                sb_state_next = SB_IDLE;
            end            
        end
        default: begin
            sb_state_next = SB_IDLE;
            sb_drain_next = 1'b0;
        end
    endcase
end

assign sb_entry_wr = {sb_id_i,1'b1, wr_addr_i, write_data_i,funct3_i};

//We write To SB if we are not Draining and its Store Instruction.
assign sb_wr_en = is_store_instr_i & ~sb_drain_reg;

//If we Have a Drain Command, And we Finish our Cache Access. We Delete From FIFO
assign sb_rd_en = sb_drain_reg & cache_access_is_done_i;

wire sb_addr_hit;
fifo #(
    .B(SB_ENTRY_SIZE),
    .W(SB_DEPTH),
    .ADDRESS_WIDTH(ADDRESS_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .VALID_BYTES(VALID_BYTES)
) sb_fifo_u (
    .clk            (   clk_i                   ),
    .reset          (   rst_i                   ),
    .rd             (   sb_rd_en                ),
    .wr             (   sb_wr_en                ),
    .w_data         (   sb_entry_wr             ),
    .load_address_i (   wr_addr_i               ),
    // .sb_id_i        (   sb_id_i                 ),
    .sb_hit         (   sb_addr_hit           ),
    .sb_hit_data    (   sb_forwarded_value_o    ),
    .empty          (   sb_empty                ),
    .full           (   sb_full                 ),
    .r_data         (   sb_entry_rd             )
);

//if SB is draining, or full Stall.
assign sb_stall_o = sb_full | sb_drain_next;

assign sb_entry_rd_o = sb_entry_rd;
assign drain_sb_o    = sb_drain_reg;
assign sb_cache_wr_o = sb_cache_wr_reg;
assign sb_load_hit_o = sb_addr_hit &  is_load_instr_i;
`ifdef CORE_VERBOSITY

reg [127:0] sb_state_reg_str, sb_state_next_str;

always @(*) begin
    case (sb_state_reg)
        SB_IDLE : sb_state_reg_str = "SB_IDLE";
        SB_DRAIN: sb_state_reg_str = "SB_DRAIN"; 
        default : sb_state_reg_str = "SB_IDLE";
    endcase
    
end

always @(*) begin
    case (sb_state_next)
        SB_IDLE : sb_state_next_str = "SB_IDLE";
        SB_DRAIN: sb_state_next_str = "SB_DRAIN"; 
        default : sb_state_next_str = "SB_IDLE";
    endcase 
end
function store_buffer_trace_log(int file);

$fwrite(file, "\nTime: %1t, Store Buffer, sb_drain_reg: %b, sb_drain_next: %b, sb_empty: %b, sb_full: %b, sb_wr_en: %b, cache_access_is_done_i: %b, sb_load_hit_o: %b", $time, sb_drain_reg,sb_drain_next,sb_empty,sb_full,sb_wr_en,cache_access_is_done_i,sb_load_hit_o);
$fwrite(file, "\nTime: %1t, Store Buffer, sb_state_reg: %0s, sb_state_next: %0s, write_data_i: 0x%h, wr_addr_i: 0x%h", $time,sb_state_reg_str,sb_state_next_str, write_data_i,wr_addr_i);
$fwrite(file, "\nTime: %1t, Store Buffer, sb_load_hit_o: %b, sb_forwarded_value_o: 0x%h, ",$time,sb_load_hit_o,sb_forwarded_value_o);
sb_fifo_u.fifo_trace_log(file);
endfunction
`endif

//Write assertion such that if FIFO is Empty, No way in Hell Next State is Drain
`ifdef ASSERTION

assert_eq sb_assert (
    .clk(clk_i),
    .test(!(sb_empty && (sb_state_next == SB_DRAIN))) //If sb_empty,  sb_state_next should never be DRAIN!
);

`endif

endmodule