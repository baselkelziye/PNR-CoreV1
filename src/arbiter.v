module arbiter (
    input  clk_i,
    input  rst_i,

    // --- DCache Interface (Request) ---
    input  dcache_req_valid_i,
    output dcache_req_ready_o,
    input  [29:0] dcache_address_i,
    input  dcache_rd_wr_i, // 0=Read, 1=Write
    input  logic dcache_data_ready_i, 
    
    input branching_i,
    // --- ICache Interface (Request) ---
    input  icache_req_valid_i,
    output icache_req_ready_o,
    input  [29:0] icache_address_i,
    input         icache_data_ready_i, 

    // --- RAM Controller Interface ---
    input  ram_ready_i,      // RAM is in IDLE (Ready to accept new request)
    input  ram_data_valid_i, // RAM asserts Valid when the operation is complete
    
    // --- RAM Request Outputs ---
    output arb_req_valid_o,  // Unified request to RAM
    output [29:0] arb_address_o,
    // output [31:0] arb_data_in_o,
    output arb_rd_wr_o,
    output arb_req_id_o,     // 1'b1=DCache, 1'b0=ICache
    
    // --- RAM Response Output (NEW: Ready signal for RAM) ---
    output  cache_ready_o, // Drives RAM.cache_ready_i

    output  dcache_resp_valid_o,
    output  icache_resp_valid_o
);

localparam DC_ID = 1'b1;
localparam IC_ID = 1'b0;

// Internal Registers for tracking the transaction and the winner
reg served_id_reg;       // ID of the currently served client (0=ICache, 1=DCache)
reg transaction_active_reg; // High from grant until RAM asserts Valid

// --- Sequential Logic ---
always @(posedge clk_i, posedge rst_i) begin
    if (rst_i) begin
        transaction_active_reg <= 1'b0;
        served_id_reg          <= IC_ID;
    end else begin
        // 1. Transaction Active Update
        if (ram_data_valid_i | (branching_i && served_id_reg == IC_ID)) begin
            // RAM signaled completion (Valid high), clear active flag
            transaction_active_reg <= 1'b0;
        end else if (dcache_req_ready_o | icache_req_ready_o) begin
            // A request was granted by the Arbiter
            transaction_active_reg <= 1'b1;
            
            // 2. Store the ID of the winner (who won access this cycle)
            if (dcache_req_ready_o) begin
                served_id_reg <= DC_ID;
            end else begin // Must be icache_req_ready_o
                served_id_reg <= IC_ID;
            end
        end
    end
end

// --- Combinational Logic ---

// 1. Request Acceptance Condition
// Request is accepted only if the RAM is IDLE AND no transaction is currently active
// We use transaction_active_reg to cover the case where RAM is busy but ram_ready_i is still high 
// (which can happen in some RAM designs, but here we simplify)
wire can_grant = ram_ready_i & ~transaction_active_reg;

// 2. Priority Logic (DCache > ICache)
// DCache wins if valid and RAM grant is possible
wire dcache_wins = dcache_req_valid_i & can_grant;

// ICache wins if valid, RAM grant is possible, AND DCache is not requesting
wire icache_wins = icache_req_valid_i & can_grant & ~dcache_req_valid_i;

// 3. Grant Signals (Cache Ready Outputs)
assign dcache_req_ready_o = dcache_wins;
assign icache_req_ready_o = icache_wins;

// 4. Unified Request Output to RAM
assign arb_req_valid_o = dcache_wins | icache_wins;

// 5. Mux Request Data (Pass the winning request's data to RAM)
assign arb_address_o = dcache_wins ? dcache_address_i : icache_address_i;
assign arb_rd_wr_o   = dcache_wins ? dcache_rd_wr_i   : 1'b0; 
// assign arb_data_in_o = dcache_wins ? dcache_data_in_i : {32{1'b0}};
assign arb_req_id_o  = dcache_wins ? DC_ID : IC_ID; // The ID of the winner

// 6. Response Ready Multiplexing (NEW)
// Drive RAM.cache_ready_i with the ready signal from the currently served client
assign cache_ready_o = transaction_active_reg ? 
                       (served_id_reg == DC_ID ? dcache_data_ready_i : icache_data_ready_i) : 
                       1'b0; // If no transaction is active, the ready signal is irrelevant (or 0)

assign dcache_resp_valid_o = ram_data_valid_i && served_id_reg == DC_ID;
assign icache_resp_valid_o = ram_data_valid_i && served_id_reg == IC_ID;

`ifdef CORE_VERBOSITY

// Wire to determine if the arbitration resulted in a grant this cycle
wire grant_this_cycle = dcache_wins | icache_wins;

// String representation of the currently served client
function automatic string served_id_to_str(logic served_id);
if (served_id == DC_ID)
    served_id_to_str = "DCACHE";
else
    served_id_to_str = "ICACHE";
endfunction

// Trace logging function
function void arbiter_trace_log(int file);
if (`CORE_VERBOSITY >= 100) begin
    // Log header: Time, Active Status, and Served ID
    $fwrite(file, "\nTime: %1t, ARBITER: Status: %s (Served: %s) | RAM_Ready: %b, RAM_Valid: %b",
            $time, 
            transaction_active_reg ? "ACTIVE" : "IDLE",
            served_id_to_str(served_id_reg),
            ram_ready_i, ram_data_valid_i);
    
    // Log Cache Requests (Inputs)
    $fwrite(file, "\n\tRequests: DCache Valid: %b, ICache Valid: %b",
            dcache_req_valid_i, icache_req_valid_i);

    // Log Arbitration Decision (Grants)
    if (grant_this_cycle) begin
        $fwrite(file, "\n\tGRANT: %s WINNER | Address: 0x%h, R/W: %b",
                dcache_wins ? "DCACHE" : "ICACHE",
                arb_address_o,
                arb_rd_wr_o);
    end else if (dcache_req_valid_i | icache_req_valid_i) begin
        $fwrite(file, "\n\tNO GRANT: Ram Not Ready (Can Grant: %b)", can_grant);
    end
    
    // Log Response Handshake Status (Outputs)
    $fwrite(file, "\n\tHandshake: Cache_Ready_o: %b, DCache_Ready_i: %b, ICache_Ready_i: %b",
            cache_ready_o, dcache_data_ready_i, icache_data_ready_i);

    // Log completion event
    if (ram_data_valid_i) begin
        $fwrite(file, "\n\t-- TRANSACTION COMPLETE (RAM Valid High) --");
    end
end
endfunction
`endif

endmodule