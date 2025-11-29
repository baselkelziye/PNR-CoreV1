`timescale 1ns / 1ps
module l1_dcache_controller 
#(
    parameter ENTRIES        = 64,
    parameter WORDS_PER_LINE = 4,
    parameter ADDRESS_WIDTH  = 32,
    parameter DATA_WIDTH     = 32,
    localparam INDEX_BITS    = $clog2(ENTRIES),
    localparam WORD_OFF_BITS = $clog2(WORDS_PER_LINE),
    localparam BYTE_OFF_BITS = 2,
    localparam TAG_SIZE      = ADDRESS_WIDTH - (INDEX_BITS + WORD_OFF_BITS + BYTE_OFF_BITS)
)
(
    input              clk_i,
    input              rst_i,
    
    // --- Interface to CPU Pipeline (Loads) ---
    input              is_load_instr_i,
    input  [29:0]      mem_byte_address_i,       

    // --- Store Buffer Slave Interface ---
    input              sb_req_valid_i,     
    input              sb_req_rw_i,        
    output             sb_req_ready_o,     
    output             sb_resp_done_o,     
    input              sb_load_hit_i,

    // --- Inputs from Cache Arrays ---
    input [TAG_SIZE-1:0]   tag_i,                  
    input [TAG_SIZE-1:0]   indexed_tag_i,
    input                  indexed_dirty_bit_i,
    input                  indexed_valid_bit_i,

    // --- Output Interface to CPU Pipeline ---
    output                 dcache_stall_o,
    output                 dcache_cntrl_valid_bit_o,
    output                 dcache_cntrl_dirty_bit_o,
    output [TAG_SIZE-1:0]  dcache_cntrl_tag_o,
    output                 dcache_cntrl_update_entry_cpu_o, 
    output                 dcache_cntrl_update_entry_mem_o, 

    // --- RAM/Arbiter Master Interface (Handshake) ---
    output logic dcache_req_valid_o,           
    input  logic dcache_req_ready_i,           
    output [29:0] dcache_address_o,            
    output logic dcache_rd_wr_o,               
    
    input  logic dcache_resp_valid_i,             
    input  logic ram_response_id_i,            
    output logic dcache_data_ready_o           
);

`include "encodings.vh" 

// --- EXPANDED FSM STATES ---
localparam [2:0] IDLE        = 3'd0,
                 COMPARE_TAG = 3'd1,
                 WB_REQ      = 3'd2, // Request Write (Eviction) -> Wait for Grant
                 ALLOC_REQ   = 3'd3, // Request Read  (Line Fill) -> Wait for Grant
                 ALLOC_WAIT  = 3'd4; // Wait for Data (Response)

localparam DCACHE_ID = 1'b1;

reg [2:0] state_reg, state_next;
reg cache_access_stall_reg, cache_access_stall_next;
reg cache_hit;

// Transaction Source Tracking (0=CPU, 1=SB)
reg trans_is_sb_reg, trans_is_sb_next;

// Internal Control Signals
reg dcache_cntrl_valid_bit, dcache_cntrl_dirty_bit;
reg [TAG_SIZE-1:0] dcache_cntrl_tag;
reg update_entry_cpu, update_entry_mem;

// Handshake Registers
reg dcache_req_valid_reg, dcache_req_valid_next;
reg dcache_data_ready_reg, dcache_data_ready_next;
reg dcache_rd_wr_next;
reg [29:0] current_ram_addr_reg; 

// Ready when IDLE
assign sb_req_ready_o = (state_reg == IDLE);

// --- Sequential Logic ---
always @(posedge clk_i) begin
    if(rst_i) begin
        state_reg               <= IDLE;
        cache_access_stall_reg  <= 1'b0;
        dcache_req_valid_reg    <= 1'b0;
        dcache_data_ready_reg   <= 1'b0;
        trans_is_sb_reg         <= 1'b0;
    end else begin
        state_reg               <= state_next;
        cache_access_stall_reg  <= cache_access_stall_next;
        dcache_req_valid_reg    <= dcache_req_valid_next;
        dcache_data_ready_reg   <= dcache_data_ready_next;
        trans_is_sb_reg         <= trans_is_sb_next;

        // Latch Address on Miss
        if((state_reg == COMPARE_TAG) && !cache_hit && (state_next == WB_REQ || state_next == ALLOC_REQ)) begin
            current_ram_addr_reg <= mem_byte_address_i;
        end
    end
end

// --- Combinational Logic (FSM) ---
always @(*) begin
    state_next              = state_reg;
    cache_access_stall_next = cache_access_stall_reg;
    trans_is_sb_next        = trans_is_sb_reg;
    cache_hit               = 1'b0;
    
    // Default Control Outputs
    dcache_cntrl_valid_bit  = dcache_cntrl_valid_bit_o;
    dcache_cntrl_dirty_bit  = dcache_cntrl_dirty_bit_o;
    dcache_cntrl_tag        = dcache_cntrl_tag_o;
    update_entry_cpu        = 1'b0;
    update_entry_mem        = 1'b0; 
    
    // Default Handshake
    dcache_req_valid_next   = dcache_req_valid_reg;
    dcache_data_ready_next  = dcache_data_ready_reg;
    dcache_rd_wr_next       = 1'b0; // Default Read
    
    dcache_address_o        = current_ram_addr_reg;
    dcache_rd_wr_o          = dcache_rd_wr_next;

    case (state_reg)
        IDLE: begin 
            dcache_req_valid_next   = 1'b0;
            dcache_data_ready_next  = 1'b0;
            cache_access_stall_next = 1'b0;

            // Priority: 1. Store Buffer, 2. CPU Load
            if (sb_req_valid_i & sb_req_rw_i) begin
                state_next = COMPARE_TAG;
                cache_access_stall_next = 1'b1;
                trans_is_sb_next = 1'b1; 
            end 
            else if (is_load_instr_i & ~sb_load_hit_i) begin
                state_next = COMPARE_TAG;
                cache_access_stall_next = 1'b1;
                trans_is_sb_next = 1'b0; 
            end
        end
        
        COMPARE_TAG: begin
            cache_hit = (tag_i == indexed_tag_i) & indexed_valid_bit_i;
            cache_access_stall_next = 1'b1;

            if(cache_hit) begin
                if(trans_is_sb_reg) begin 
                    dcache_cntrl_valid_bit = 1'b1;
                    dcache_cntrl_dirty_bit = 1'b1;
                    dcache_cntrl_tag       = tag_i;
                    update_entry_cpu       = 1'b1; 
                    cache_access_stall_next = 1'b0;
                    state_next = IDLE; // Hit -> Done
                end 
            end else begin 
                // MISS: Determine if we need to Write-Back (Evict) or just Allocate
                if(indexed_dirty_bit_i) begin
                    state_next = WB_REQ;      // Dirty? Go to Write Request
                    dcache_req_valid_next = 1'b1; 
                    dcache_rd_wr_next     = 1'b1; // Write
                end else begin 
                    state_next = ALLOC_REQ;   // Clean? Go to Read Request
                    dcache_req_valid_next = 1'b1; 
                    dcache_rd_wr_next     = 1'b0; // Read
                end
            end
        end
        
        WB_REQ: begin
            // 1. Assert Request (Write)
            dcache_rd_wr_next     = 1'b1;                 
            dcache_req_valid_next = 1'b1;  
            cache_access_stall_next = 1'b1;

            // 2. Wait for Grant (Ready)
            if(dcache_req_valid_reg & dcache_req_ready_i) begin
                // Request Accepted. 
                // We assume Arbiter buffers the write. We can immediately start the Read.
                dcache_req_valid_next = 1'b0; 
                state_next            = ALLOC_REQ; // Now fetch the new line
                
                // Note: If you need to re-assert Request for the Read in the same cycle,
                // you would keep valid high and flip rd_wr. But usually, we drop valid 
                // for 1 cycle or handle it in the next state. Here we drop it.
                // To save a cycle, you could do: dcache_req_valid_next = 1; dcache_rd_wr_next = 0;
            end
        end
        
        ALLOC_REQ: begin
            // 1. Assert Request (Read)
            dcache_rd_wr_next = 1'b0; 
            cache_access_stall_next = 1'b1;

            if (dcache_req_valid_reg == 1'b0) begin
                // If coming from WB_REQ, valid might be low for 1 cycle, pull it high
                dcache_req_valid_next = 1'b1;
            end else begin
                dcache_req_valid_next = 1'b1;
                // 2. Wait for Grant
                if(dcache_req_ready_i) begin
                    dcache_req_valid_next = 1'b0; // Grant received
                    state_next = ALLOC_WAIT;      // Move to Data Phase
                end
            end
        end

        ALLOC_WAIT: begin
            // 1. Wait for Data
            cache_access_stall_next = 1'b1;
            dcache_req_valid_next   = 1'b0;
            dcache_data_ready_next  = 1'b1; // We are ready for data

            // 2. Check Data Valid
            if(dcache_resp_valid_i & dcache_data_ready_reg) begin
                dcache_data_ready_next    = 1'b0; 
                
                // Update Cache Array
                dcache_cntrl_valid_bit    = 1'b1;
                dcache_cntrl_dirty_bit    = 1'b0; 
                dcache_cntrl_tag          = tag_i;
                update_entry_mem          = 1'b1; 
                
                // Done
                state_next                = COMPARE_TAG; 
            end
        end

        default: begin
            state_next = IDLE;
            cache_access_stall_next = 1'b0;
        end
    endcase
end

// --- Output Assignments ---
assign dcache_stall_o               = cache_access_stall_next; 
assign dcache_cntrl_valid_bit_o     = dcache_cntrl_valid_bit;
assign dcache_cntrl_dirty_bit_o     = dcache_cntrl_dirty_bit;
assign dcache_cntrl_tag_o           = dcache_cntrl_tag;
assign dcache_cntrl_update_entry_cpu_o = update_entry_cpu;
assign dcache_cntrl_update_entry_mem_o = update_entry_mem;

assign dcache_req_valid_o           = dcache_req_valid_reg;  
assign dcache_data_ready_o          = dcache_data_ready_reg; 

// Done Signal for Store Buffer (Only pulse if SB initiated transaction)
wire generic_access_done = cache_access_stall_reg & ~cache_access_stall_next;
assign sb_resp_done_o    = generic_access_done & trans_is_sb_reg;
`ifdef CORE_VERBOSITY

// String representation of the current state
reg [511:0] state_str_reg;
reg [511:0] state_str_next;

always @* begin
    case (state_reg)
      IDLE:        state_str_reg = "IDLE";
      COMPARE_TAG: state_str_reg = "COMPARE_TAG";
      WB_REQ:      state_str_reg = "WB_REQ (Evict Req)";
      ALLOC_REQ:   state_str_reg = "ALLOC_REQ (Read Req)";
      ALLOC_WAIT:  state_str_reg = "ALLOC_WAIT (Wait Data)";
      default:     state_str_reg = "UNKNOWN";
    endcase
  end
  always @* begin
    case (state_next)
      IDLE:        state_str_next = "IDLE";
      COMPARE_TAG: state_str_next = "COMPARE_TAG";
      WB_REQ:      state_str_next = "WB_REQ (Evict Req)";
      ALLOC_REQ:   state_str_next = "ALLOC_REQ (Read Req)";
      ALLOC_WAIT:  state_str_next = "ALLOC_WAIT (Wait Data)";
      default:     state_str_next = "UNKNOWN";
    endcase
  end
  function void dcache_controller_trace_log(int file);
  $fwrite(file, "\nTime: %1t, dcache controller, state_str_reg: %0s, state_str_next: %0s, sb_req_valid_i: %b, sb_req_ready_o: %b, sb_resp_done_o: %b",$time, state_str_reg, state_str_next,sb_req_valid_i,sb_req_ready_o,sb_resp_done_o);
endfunction

`endif 

endmodule