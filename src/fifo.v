`define VALID_BYTES_IDX VALID_BYTES-1:0 // 2:0
`define DATA_IDX VALID_BYTES+DATA_WIDTH-1:VALID_BYTES
`define ADDRESS_IDX ADDRESS_WIDTH+VALID_BYTES+DATA_WIDTH-1:VALID_BYTES+DATA_WIDTH
`define VALID_BIT_IDX ADDRESS_WIDTH+VALID_BYTES+DATA_WIDTH
`define SB_ID_IDX SB_ID_SIZE+ADDRESS_WIDTH+VALID_BYTES+DATA_WIDTH:ADDRESS_WIDTH+VALID_BYTES+DATA_WIDTH+1

module fifo
#(parameter B=76,  // 8(ID) + 1(valid) + 32(addr) + 32(data) + 3(valid_byte)
  parameter W=4, // FIFO depth is 2^W
  parameter ADDRESS_WIDTH = 32,
  parameter DATA_WIDTH = 32,
  parameter VALID_BYTES = 3,
  parameter SB_ID_SIZE = 8,
  localparam SB_ENTRY_SIZE = ADDRESS_WIDTH + DATA_WIDTH + VALID_BYTES + SB_ID_SIZE + 1,
  localparam FIFO_DEPTH = 2**W
  )(
    input wire clk, reset,
    input wire rd, wr,
    input wire [B-1:0] w_data,
    input wire [ADDRESS_WIDTH-1:0] load_address_i,
    
    output wire empty, full,
    output wire [B-1:0] r_data,
    
    // Forwarding outputs
    output reg sb_hit,
    output reg [DATA_WIDTH-1:0] sb_hit_data,
    output reg [VALID_BYTES-1:0] sb_hit_valid_byte
);

// --- FIFO State and Pointers ---

reg [B-1:0] array_reg [FIFO_DEPTH-1:0];
reg [W-1:0] w_ptr_reg, w_ptr_next, w_ptr_succ;
reg [W-1:0] r_ptr_reg, r_ptr_next, r_ptr_succ;
reg full_reg, empty_reg, full_next, empty_next;
wire wr_en;
wire rd_en;

// --- FIFO Memory Access Logic ---
integer k;
always @(posedge clk) begin
    if(reset) begin
        for(k = 0;k < 2**W; k = k+1) begin
            array_reg[k] = '0;
        end
    end else begin
        if(wr_en)
            array_reg[w_ptr_reg] <= w_data;
        if(rd_en)  // Clear valid bit on read for the entry just read out (important for forwarding)
            array_reg[r_ptr_reg][`VALID_BIT_IDX] <= 1'b0;
    end
end

assign r_data = array_reg[r_ptr_reg];
assign wr_en = wr & ~full_reg;
assign rd_en = rd & ~empty_reg;

// --- FIFO Pointer Control Logic ---

always @(posedge clk, posedge reset) begin
    if(reset) begin
        w_ptr_reg <= 0;
        r_ptr_reg <= 0;
        full_reg <= 1'b0;
        empty_reg <= 1'b1;
    end else begin
        w_ptr_reg <= w_ptr_next;
        r_ptr_reg <= r_ptr_next;
        full_reg <= full_next;
        empty_reg <= empty_next;
    end
end

always @* begin
    w_ptr_succ = w_ptr_reg + 1;
    r_ptr_succ = r_ptr_reg + 1;
    
    w_ptr_next = w_ptr_reg;
    r_ptr_next = r_ptr_reg;
    full_next = full_reg;
    empty_next = empty_reg;
    
    // State machine for pointer updates
    case ({wr,rd})
        2'b01: // read
            if(~empty_reg) begin
                r_ptr_next = r_ptr_succ;
                full_next = 1'b0;
                if(r_ptr_succ == w_ptr_reg)
                    empty_next = 1'b1;
            end
        2'b10: // write
            if(~full_reg) begin
                w_ptr_next = w_ptr_succ;
                empty_next = 1'b0;
                if(w_ptr_succ == r_ptr_reg)
                    full_next = 1'b1;       
            end
        2'b11: begin // simultaneous read and write
            w_ptr_next = w_ptr_succ;
            r_ptr_next = r_ptr_succ;
            // Full/empty state is preserved when both happen
        end 
    endcase
end

// --- Store Buffer Forwarding (Bypassing) Logic ---

// 1. Parallel Address Matching
// addr_match_valid[i] is true if entry i is valid AND its address matches the load address
wire [FIFO_DEPTH-1:0] addr_match_valid;

genvar i;
generate 
    for(i = 0; i < FIFO_DEPTH; i = i+1) begin : g_sb_match
        // Match only if valid bit is set AND address matches load_address_i
        assign addr_match_valid[i] = array_reg[i][`VALID_BIT_IDX] && 
                                     (array_reg[i][`ADDRESS_IDX] == load_address_i);
    end
endgenerate

// 2. Priority Resolution (Find Highest SB_ID among matches)
// This is fully combinational logic to determine the newest matching store.

always @* begin
    // Declare a local integer for procedural loops (fixes the genvar error)
    integer j; 
    
    // Initialize search variables
    reg [SB_ID_SIZE-1:0] max_id_found;
    reg [W-1:0] winner_index;
    
    max_id_found = {SB_ID_SIZE{1'b0}}; // Start comparison from ID 0
    winner_index = {W{1'b0}};          // Default index (can be any value if no hit)
    
    sb_hit = 1'b0; // Default to no hit
    
    // Iterate through all entries to find the one with the highest SB_ID among matches
    for (j = 0; j < FIFO_DEPTH; j = j + 1) begin // Using local integer j
        if (addr_match_valid[j]) begin
            // We have at least one hit
            sb_hit = 1'b1;
            
            // Check if this match has a higher (newer) ID than the current best
            if (array_reg[j][`SB_ID_IDX] > max_id_found) begin
                max_id_found = array_reg[j][`SB_ID_IDX];
                winner_index = j; // Update the index of the newest match
            end
        end
    end

    // 3. Output Assignment
    if (sb_hit) begin
        // Assign the data from the winning entry
        sb_hit_data       = array_reg[winner_index][`DATA_IDX];
        sb_hit_valid_byte = array_reg[winner_index][`VALID_BYTES_IDX];
    end else begin
        // No hit, drive outputs to a default/zero state
        sb_hit_data       = {DATA_WIDTH{1'b0}};
        sb_hit_valid_byte = {VALID_BYTES{1'b0}};
    end
end


// --- Final Output Assignments ---

assign full = full_next;
assign empty = empty_next;

// The rest of the forwarding logic is handled by the combinational block above.


`ifdef CORE_VERBOSITY
function void fifo_trace_log(int file);
integer i;
reg [2**W-1:0] extra_pad;
for(i = 0; i < (2**W); i = i+1) begin
    $fwrite(file,"\n");
    
    if(r_ptr_reg == i && w_ptr_reg == i) begin
        $fwrite(file, "W/R -> ");
    end else if(r_ptr_reg == i) begin
        $fwrite(file, "R -> ");
    end else if(w_ptr_reg == i) begin
        $fwrite(file, "W -> ");
    end else begin
        // Check if this is a W/R collision case that needs extra padding
        if(r_ptr_reg == w_ptr_reg && (r_ptr_reg < (2**W))) begin
            $fwrite(file,"       ");  // 7 spaces for W/R collision case
        end else begin
            $fwrite(file,"     ");    // 5 spaces for normal case
        end
    end

    $fwrite(file, "SB[%1d]: sb_id: %d, valid_bit: %b, address: 0x%h, data: 0x%h valid_bytes: %b", i,array_reg[i][`SB_ID_IDX], array_reg[i][`VALID_BIT_IDX],array_reg[i][`ADDRESS_IDX],array_reg[i][`DATA_IDX], array_reg[i][`VALID_BYTES_IDX]);
end

endfunction

`endif
endmodule