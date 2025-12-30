module l1_icache_controller(
    input clk_i,
    input rst_i,

    // --- Output Interface to CPU Pipeline (Fetch Stage) ---
    output icache_fill_stall_o,
    output icache_fill_line_o, // Signal to cache RAM to accept fill data
    
    // --- Request Interface to Arbiter ---
    output icache_req_valid_o, // Our request is active (Valid)
    input  icache_req_ready_i, // Arbiter grants access (Ready)
    
    // --- Response Interface from RAM ---
    input  icache_resp_valid_i,   // RAM has data ready (Valid)
    input  ram_response_id_i,  // ID of the requester that is being served (0=ICache)
    output icache_data_ready_o, // We are ready to accept data (Ready)
    
    // --- Internal Status ---
    input  icache_hit_i,       // Cache Hit signal (input from Cache Tag logic)
    input  branch_ex_i         // Branch/Exception flush signal
);

// Constants for State Machine
localparam [1:0] I_IDLE      = 2'b00,  // Waiting for cache miss
                 I_REQUEST   = 2'b01,  // Asserting valid, waiting for Arbiter grant (Ready)
                 I_WAIT_FILL = 2'b10;  // Request granted, waiting for RAM data/response

// Constants for memory ID (Must match Arbiter/RAM definition)
localparam ICACHE_ID = 1'b0;

reg [1:0] icache_state_reg, icache_state_next;
// Request Handshake Signals
reg icache_req_valid_reg, icache_req_valid_next;
// Response Handshake Signals
reg icache_data_ready_reg, icache_data_ready_next;

// Pipeline control and Data Transfer Signals
reg icache_stall_reg, icache_stall_next;
reg icache_fill_line;

// Sequential Logic
always @(posedge clk_i) begin
    if(rst_i) begin
        icache_state_reg        <= I_IDLE;
        icache_req_valid_reg    <= 1'b0;
        icache_data_ready_reg   <= 1'b0;
        icache_stall_reg        <= 1'b0;
    end else begin
        icache_state_reg        <= icache_state_next;
        icache_req_valid_reg    <= icache_req_valid_next;
        icache_data_ready_reg   <= icache_data_ready_next;
        icache_stall_reg        <= icache_stall_next;
    end
end

// Combinational Logic (FSM)
always @(*) begin
    icache_state_next       = icache_state_reg;
    icache_req_valid_next   = icache_req_valid_reg;
    icache_data_ready_next  = icache_data_ready_reg;
    icache_stall_next       = icache_stall_reg;
    icache_fill_line        = 1'b0;

    // --- Branch/Exception Flush Logic ---
    // If a flush occurs, abort current transaction and return to IDLE immediately.
    if (branch_ex_i) begin
        icache_state_next       = I_IDLE;
        icache_req_valid_next   = 1'b0; // Cancel request
        icache_data_ready_next  = 1'b0; // Stop receiving
        icache_stall_next       = 1'b0; // Clear stall
        icache_fill_line        = 1'b0;
    end else begin
        
        case (icache_state_reg)
            I_IDLE: begin
                icache_stall_next       = 1'b0;
                icache_req_valid_next   = 1'b0;
                icache_data_ready_next  = 1'b0;
                
                if(~icache_hit_i) begin // Cache Miss
                    icache_state_next       = I_REQUEST;
                    icache_req_valid_next   = 1'b1; // Start request
                    icache_stall_next       = 1'b1; // Stall the fetch stage
                end
            end
            
            I_REQUEST: begin
                // Maintain stall and request valid signal until granted
                icache_stall_next       = 1'b1;
                icache_req_valid_next   = 1'b1;
                icache_data_ready_next  = 1'b0;
                
                // Successful Request Handshake: valid & ready high
                if(icache_req_valid_reg & icache_req_ready_i) begin
                    icache_state_next       = I_WAIT_FILL;
                    icache_req_valid_next   = 1'b0; // Request accepted, de-assert valid
                end
            end
            
            I_WAIT_FILL: begin
                // Maintain stall until data arrives
                icache_stall_next       = 1'b1;
                icache_req_valid_next   = 1'b0;
                
                // Assert ready to receive data from RAM
                icache_data_ready_next  = 1'b1; 
                
                // Successful Response Handshake: data valid & ready high AND correct ID
                if(icache_resp_valid_i & icache_data_ready_reg) begin
                    icache_state_next       = I_IDLE;
                    // icache_stall_next       = 1'b0; // Release stall
                    icache_fill_line        = 1'b1; // Signal cache RAM to write the data
                    icache_data_ready_next  = 1'b0; // Stop receiving
                end
            end
            
            default: begin
                icache_state_next       = I_IDLE;
                icache_req_valid_next   = 1'b0;
                icache_data_ready_next  = 1'b0;
                icache_stall_next       = 1'b0;
            end
        endcase
    end
end

// Output Assignments
assign icache_fill_stall_o  = icache_stall_next;      // Stall reflects the registered state
assign icache_fill_line_o   = icache_fill_line;      // Pulse signal to load the line
assign icache_req_valid_o   = icache_req_valid_reg;  // Request Valid signal to Arbiter
assign icache_data_ready_o  = icache_data_ready_reg; // Data Ready signal to RAM


`ifdef CORE_VERBOSITY

reg [511:0] icache_state_str_reg;
reg [511:0] icache_state_str_next;

always @* begin
  case (icache_state_reg)
    I_IDLE:      icache_state_str_reg = "I_IDLE";
    I_REQUEST:   icache_state_str_reg = "I_REQUEST (Wait Grant)";
    I_WAIT_FILL: icache_state_str_reg = "I_WAIT_FILL (Wait Data)";
    default:     icache_state_str_reg = "I_UNKNOWN";
  endcase
end

always @* begin
  case (icache_state_next)
    I_IDLE:      icache_state_str_next = "I_IDLE";
    I_REQUEST:   icache_state_str_next = "I_REQUEST (Wait Grant)";
    I_WAIT_FILL: icache_state_str_next = "I_WAIT_FILL (Wait Data)";
    default:     icache_state_str_next = "I_UNKNOWN";
  endcase
end

function void icache_controller_trace_log(int file);
    $fwrite(file, "\nTime: %1t, ICache Controller, state_reg: %0s, state_next: %0s, icache_hit: %b, stall: %b", 
            $time, icache_state_str_reg, icache_state_str_next, icache_hit_i, icache_fill_stall_o);
    $fwrite(file, "\nTime: %1t, ICache Controller, REQ_VALID: %b, REQ_READY: %b, DATA_VALID: %b, DATA_READY: %b, ID: %b",
            $time, icache_req_valid_o, icache_req_ready_i, icache_resp_valid_i, icache_data_ready_o, ram_response_id_i);
    
    if (`CORE_VERBOSITY >= 600) begin
        case (icache_state_reg)
            I_IDLE: begin
                if (~icache_hit_i) begin
                    $fwrite(file, "\nTime: %1t, ICache Controller -> Cache Miss detected, issuing request (I_REQUEST)", $time);
                end else if (branch_ex_i) begin
                    $fwrite(file, "\nTime: %1t, ICache Controller -> Branch/Exception flush received. Transitioning to IDLE.", $time);
                end
            end
            I_REQUEST: begin
                if (icache_req_ready_i) begin
                    $fwrite(file, "\nTime: %1t, ICache Controller -> Request granted by Arbiter, waiting for data (I_WAIT_FILL)", $time);
                end else begin
                    $fwrite(file, "\nTime: %1t, ICache Controller -> Request waiting for Arbiter grant. Stalling Fetch.", $time);
                end
            end
            I_WAIT_FILL: begin
                if (icache_resp_valid_i & (ram_response_id_i == ICACHE_ID)) begin
                    $fwrite(file, "\nTime: %1t, ICache Controller -> Response Handshake successful. Cache line filled, unstalling.", $time);
                end else begin
                    $fwrite(file, "\nTime: %1t, ICache Controller -> Waiting for RAM response (Valid/ID check).", $time);
                end
            end
        endcase
    end
endfunction

`endif


endmodule