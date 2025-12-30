`timescale 1ns / 1ps

module store_buffer
#(
    parameter ADDRESS_WIDTH = 32,
    parameter DATA_WIDTH    = 32,
    parameter VALID_BYTES   = 3,
    parameter SB_DEPTH      = 4, 
    parameter SB_ID_SIZE    = 8,
    parameter SB_ENTRY_SIZE = ADDRESS_WIDTH + DATA_WIDTH + VALID_BYTES + 1 + SB_ID_SIZE
)
(
    input clk_i,
    input rst_i,


    input is_store_instr_i,
    input is_load_instr_i,
    input [31:0] wr_addr_i,
    input [31:0] write_data_i,
    output [SB_ENTRY_SIZE-1:0] sb_entry_rd_o,
    input rob_drain_req_i, //Store needs to commit, From ROB
    output drain_sb_o,
    input [2:0] funct3_i,
    input [SB_ID_SIZE-1:0] sb_id_i,
    
    input trap_en_mem_i,
    input trap_en_wb_i,
    input rob_flush_i,
    input rob_exception_i,
    input rob_sret_i,

    output                      sb_req_valid_o, 
    output                      sb_req_rw_o,    
    input                       dcache_req_ready_i, // "DCache is readt to accept
    input                       dcache_resp_done_i, // "Write Finished"
    output                      sb_stall_o,     
    output                      sb_load_hit_o,  
    output [DATA_WIDTH-1:0]     sb_forwarded_value_o
);

`include "encodings.vh"

localparam [1:0] SB_IDLE       = 2'b00,
                 SB_REQ_ACTIVE = 2'b01; 

reg [1:0] sb_state_reg, sb_state_next;
reg sb_req_valid_reg, sb_req_valid_next;

wire sb_empty, sb_full;
wire sb_wr_en, sb_rd_en;
reg sb_drain_reg, sb_drain_next;
wire [SB_ENTRY_SIZE-1:0] sb_entry_wr, sb_entry_rd;

// ----------------------------------------------------------------
// FSM: Master Handshake Logic
// ----------------------------------------------------------------
always @(posedge clk_i) begin
    if(rst_i) begin
        sb_state_reg     <= SB_IDLE;
        sb_req_valid_reg <= 1'b0;
        sb_drain_reg     <= 1'b0;
    end else begin
        sb_state_reg     <= sb_state_next;
        sb_req_valid_reg <= sb_req_valid_next;
        sb_drain_reg     <= sb_drain_next;
    end
end

always @(*) begin
    sb_state_next     = sb_state_reg;
    sb_req_valid_next = sb_req_valid_reg;
    sb_drain_next = sb_drain_reg;
    case (sb_state_reg)
        SB_IDLE: begin
            // We only start a request if:
            // 1. We have Drain Request
            // 2. The DCache is ready to recieve
            if (rob_drain_req_i & dcache_req_ready_i) begin
                sb_state_next     = SB_REQ_ACTIVE;
                sb_req_valid_next = 1'b1; // START REQUEST
                sb_drain_next = 1'b1;
            end else begin
                sb_req_valid_next = 1'b0;
                sb_drain_next = 1'b0;
            end
        end

        SB_REQ_ACTIVE: begin
            // Hold Valid High until we get the "Done" pulse from DCache
            sb_req_valid_next = 1'b1; 

            if (dcache_resp_done_i) begin
                // DCache said "Done". We can drop the request.
                sb_req_valid_next = 1'b0;
                sb_drain_next   = 1'b0;
                sb_state_next     = SB_IDLE; 
            end
        end
        default: begin
            sb_state_next = SB_IDLE;
            sb_drain_next   = 1'b0;
            sb_state_next     = SB_IDLE; 
        end 
    endcase
end

// ----------------------------------------------------------------
// FIFO Control
// ----------------------------------------------------------------

// PUSH (Write to FIFO): From Pipeline
assign sb_wr_en = is_store_instr_i  & ~sb_drain_reg;

// POP (Read from FIFO): When transaction is completely DONE
assign sb_rd_en = sb_drain_reg & dcache_resp_done_i;
assign drain_sb_o = sb_drain_reg;

// ----------------------------------------------------------------
// Data Processing & FIFO Instance
// ----------------------------------------------------------------
wire [1:0] byte_off = wr_addr_i[1:0];
reg [31:0] updated_sb_wr_data;
wire sb_addr_hit;

// Forwarding Logic (Merging current write with older pending writes if they exist)
always @* begin
    if(sb_addr_hit & is_store_instr_i) begin 
        updated_sb_wr_data = sb_forwarded_value_o;
        case (funct3_i)
            `SB_FUNCT3: begin
                case (byte_off)
                    2'b00: updated_sb_wr_data[7:0  ] = write_data_i[7:0]; 
                    2'b01: updated_sb_wr_data[15:8 ] = write_data_i[7:0];
                    2'b10: updated_sb_wr_data[23:16] = write_data_i[7:0];
                    2'b11: updated_sb_wr_data[31:24] = write_data_i[7:0];
                endcase
            end 
            `SH_FUNCT3: begin
                if(byte_off[1] == 1'b0) updated_sb_wr_data[15:0]  = write_data_i[15:0];
                else                    updated_sb_wr_data[31:16] = write_data_i[15:0];
            end
            `SW_FUNCT3: updated_sb_wr_data = write_data_i;
            default:    updated_sb_wr_data = write_data_i;
        endcase   
    end else begin
        updated_sb_wr_data = write_data_i;
    end
end

assign sb_entry_wr = {sb_id_i, 1'b1, wr_addr_i, updated_sb_wr_data, funct3_i};

fifo #(
    .B(SB_ENTRY_SIZE),
    .W(SB_DEPTH),
    .ADDRESS_WIDTH(ADDRESS_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .VALID_BYTES(VALID_BYTES)
) sb_fifo_u (
    .clk            (   clk_i                   ),
    .reset          (   rst_i |rob_flush_i | rob_exception_i | rob_sret_i),
    .rd             (   sb_rd_en                ),
    .wr             (   sb_wr_en                ),
    .w_data         (   sb_entry_wr             ),
    .load_address_i (   wr_addr_i               ),
    .sb_hit         (   sb_addr_hit             ),
    .sb_hit_data    (   sb_forwarded_value_o    ),
    .empty          (   sb_empty                ),
    .full           (   sb_full                 ),
    .r_data         (   sb_entry_rd             )
);

// ----------------------------------------------------------------
// Output Assignments
// ----------------------------------------------------------------

// 1. Stall Pipeline if SB is full or if we are actively draining (Busy)
//    (Note: If you want non-blocking stores, you can remove the "sb_state_reg" check here,
//     but you need dual-port RAM or arbitration logic in the cache).
assign sb_stall_o     = sb_full | (sb_state_reg == SB_REQ_ACTIVE);

// 2. Forwarding Hit
assign sb_load_hit_o  = sb_addr_hit & is_load_instr_i;

// 3. Handshake Outputs
assign sb_req_valid_o = sb_req_valid_reg; 
assign sb_req_rw_o    = 1'b1; // Always a write
assign sb_entry_rd_o = sb_entry_rd;

`ifdef CORE_VERBOSITY

reg [127:0] sb_state_reg_str, sb_state_next_str;

always @(*) begin
    case (sb_state_reg)
        SB_IDLE : sb_state_reg_str = "SB_IDLE";
        SB_REQ_ACTIVE: sb_state_reg_str = "SB_REQ_ACTIVE"; 
        default : sb_state_reg_str = "SB_IDLE";
    endcase
    
end

always @(*) begin
    case (sb_state_next)
        SB_IDLE : sb_state_next_str = "SB_IDLE";
        SB_REQ_ACTIVE: sb_state_next_str = "SB_REQ_ACTIVE"; 
        default : sb_state_next_str = "SB_IDLE";
    endcase 
end
function store_buffer_trace_log(int file);
$fwrite(file, "\nTime: %1t, Store Buffer, sb_state_reg: %0s, sb_state_next: %0s, sb_empty: %b, sb_full: %b ",$time,sb_state_reg_str,sb_state_next_str, sb_empty, sb_full );
$fwrite(file, "\nTime: %1t, Store Buffer, is_store_instr_i: %b, is_load_instr_i: %b, wr_addr_i: 0x%h, wr_data_i: 0x%h, funct3_i: %b, sb_id_i: %d",$time, is_store_instr_i,is_load_instr_i,wr_addr_i, write_data_i,funct3_i,sb_id_i);
$fwrite(file, "\nTime: %1t, Store Buffer, REQ: sb_req_valid_o: %b, dcache_req_ready_i: %b, RESP: dcache_resp_done_i: %b", $time, sb_req_valid_o,dcache_req_ready_i,dcache_resp_done_i);
sb_fifo_u.fifo_trace_log(file);
endfunction

`endif
// function store_buffer_trace_log(int file);

// $fwrite(file, "\nTime: %1t, Store Buffer, sb_drain_reg: %b, sb_drain_next: %b, sb_empty: %b, sb_full: %b, sb_wr_en: %b, cache_access_is_done_i: %b, sb_load_hit_o: %b", $time, sb_drain_reg,sb_drain_next,sb_empty,sb_full,sb_wr_en,cache_access_is_done_i,sb_load_hit_o);
// $fwrite(file, "\nTime: %1t, Store Buffer, sb_state_reg: %0s, sb_state_next: %0s, updated_sb_wr_data: 0x%h, wr_addr_i: 0x%h", $time,sb_state_reg_str,sb_state_next_str, updated_sb_wr_data,wr_addr_i);
// $fwrite(file, "\nTime: %1t, Store Buffer, sb_load_hit_o: %b, sb_forwarded_value_o: 0x%h, ",$time,sb_load_hit_o,sb_forwarded_value_o);

// endfunction
// `endif

// //Write assertion such that if FIFO is Empty, No way in Hell Next State is Drain
// `ifdef ASSERTION

// assert_eq sb_assert (
//     .clk(clk_i),
//     .test(!(sb_empty && (sb_state_next == SB_DRAIN))) //If sb_empty,  sb_state_next should never be DRAIN!
// );

// `endif

endmodule