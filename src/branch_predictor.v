module branch_predictor
#(parameter N = 4)(
    input clk_i,
    input rst_i,

    input [31:0] pc_i,            // PC in IF stage
    input [31:0] pc_ex_i,         // PC in EX stage (where branch resolves)
    input [31:0] btb_address_value_i, // ALU result (target address) from EX
    input update_btb_address_i,       // Control signal to update BTB

    // 2-Bit Predictor Signals
    input increment_counter,
    input decrement_counter,

    output [31:0] btb_fetched_address_o,
    output branch_is_taken
    
);

localparam [1:0]
  STRONGLY_NOT_TAKEN = 2'b00,
  WEAKLY_NOT_TAKEN   = 2'b01,
  WEAKLY_TAKEN       = 2'b10,
  STRONGLY_TAKEN     = 2'b11;

// N is the number of index bits (e.g., 10 for 1024 entries)
localparam INDEX_SIZE = N; 
localparam INDEX_LSB  = 2; // Instructions are 4-byte aligned (bits 1:0 are 00)
localparam INDEX_MSB  = INDEX_LSB + INDEX_SIZE - 1; // e.g., 2 + 10 - 1 = 11

localparam TAG_LSB = INDEX_MSB + 1; // e.g., 12
localparam BTB_TAG_SIZE = 32 - TAG_LSB; // e.g., 32 - 12 = 20 bits

// ----------------------------------------------------
// 1. Address Slicing
// ----------------------------------------------------

// Calculate Index for IF (Prediction) and EX (Update)
wire [INDEX_SIZE-1:0] if_index = pc_i[INDEX_MSB:INDEX_LSB];
wire [INDEX_SIZE-1:0] ex_index = pc_ex_i[INDEX_MSB:INDEX_LSB];

// Calculate Tag for IF (Prediction) and EX (Update)
wire [BTB_TAG_SIZE-1:0] if_tag = pc_i[31:TAG_LSB];
wire [BTB_TAG_SIZE-1:0] ex_tag = pc_ex_i[31:TAG_LSB];


// ----------------------------------------------------
// 2. BTB and BHT Storage
// ----------------------------------------------------

reg [31:0]              BTB[0:2**N-1];
reg [BTB_TAG_SIZE-1:0]  BTB_tag[0:2**N-1];
reg [1:0]               branch_history_buffer[0:2**N-1]; 

integer i;

wire BTB_hit;
wire [1:0] if_pc_counter_2bit_counter, ex_pc_2bit_counter;

// Read the BHT values using the calculated indices
assign ex_pc_2bit_counter       = branch_history_buffer[pc_ex_i[N:2]];
assign if_pc_counter_2bit_counter = branch_history_buffer[pc_i[N:2]];


// ----------------------------------------------------
// 3. BTB Update Logic (Write)
// ----------------------------------------------------

always @(posedge clk_i, posedge rst_i) begin
    if(rst_i) begin
        for(i = 0; i < 2**N; i = i+1) begin
            BTB[i] = 32'h0;
            BTB_tag[i] = '0;
        end
    end else begin
        // Only update on write signal
        if(update_btb_address_i) begin
            BTB[ex_index]     <= btb_address_value_i; // Target address
            BTB_tag[ex_index] <= ex_tag;              // Tag
        end
    end
end


// ----------------------------------------------------
// 4. BHT Update Logic (Write)
// ----------------------------------------------------

always @(posedge clk_i, posedge rst_i)
begin 
  if(rst_i)
    for(i = 0; i < 2**N; i = i + 1)
        branch_history_buffer[i] = STRONGLY_NOT_TAKEN;
  else
  begin
    // Increment: branch taken, counter < STRONGLY_TAKEN (11)
    if(increment_counter && (ex_pc_2bit_counter != STRONGLY_TAKEN))
        branch_history_buffer[ex_index] <= branch_history_buffer[ex_index] + 2'b1;
    // Decrement: branch not taken, counter > STRONGLY_NOT_TAKEN (00)
    else if(decrement_counter && (ex_pc_2bit_counter != STRONGLY_NOT_TAKEN))
        branch_history_buffer[ex_index] <= branch_history_buffer[ex_index] - 2'b1;
  end
end

// ----------------------------------------------------
// 5. Prediction Logic (Read)
// ----------------------------------------------------

// Predicted target address (if BTB hits)
assign btb_fetched_address_o = BTB[if_index];

// BTB Hit Check: Tag matches the PC tag for the indexed entry
assign BTB_hit = BTB_tag[if_index] == if_tag && BTB_tag[if_index] != 32'h0;

// Branch Prediction: Taken if prediction is >= Weakly Taken (Bit 1 is high) AND BTB Hit
assign branch_is_taken = if_pc_counter_2bit_counter[1] && BTB_hit;

`ifdef CORE_VERBOSITY

function void branch_predictor_trace_log(int file);
$fwrite(file, "\nTime: %1t, Branch Predictor, pc_i: 0x%h, pc_ex_i: 0x%h, btb_address_value_i : 0x%h, update_btb_address_i: %b", $time, pc_i,pc_ex_i,btb_address_value_i,update_btb_address_i);
$fwrite(file, "\nTime: %1t, Branch Predictor, inc_counter: %b, dec_counter: %b, btb_fetched_address_o: 0x%h, branch_is_taken: %b",$time,increment_counter,decrement_counter,btb_fetched_address_o,branch_is_taken);
endfunction

function void BTB_trace_log(int file);
    integer idx;
    logic [INDEX_SIZE-1:0] index_bits_iterator;
    logic valid;
    string bht_state;
    logic prediction;
    
    $fwrite(file, "\nTime: %1t, BTB Array, if_index: 0x%h, if_tag: 0x%h, ex_index: 0x%h, ex_tag: 0x%h", 
            $time, if_index, if_tag, ex_index, ex_tag);
    $fwrite(file, "\n BTB_hit: %b, if_pc_counter: %b, ex_pc_counter: %b", 
            BTB_hit, if_pc_counter_2bit_counter, ex_pc_2bit_counter);
    
    if(`CORE_VERBOSITY >= 600) begin
        $fwrite(file, "\n Index, Valid,   Tag       Target Address      BHT State     Prediction");
        $fwrite(file, "\n");
        
        for (idx = 0; idx < 2**N; idx = idx + 1) begin  
            index_bits_iterator = idx;
            
            // Determine validity (entry is valid if tag is non-zero)
            valid = (BTB_tag[idx] != 0);
            
            // Determine BHT state name
            case (branch_history_buffer[idx])
                STRONGLY_NOT_TAKEN: bht_state = "SNT";
                WEAKLY_NOT_TAKEN:   bht_state = "WNT"; 
                WEAKLY_TAKEN:       bht_state = "WT";
                STRONGLY_TAKEN:     bht_state = "ST";
                default:            bht_state = "XXX";
            endcase
            
            // Determine prediction (taken if bit 1 is high)
            prediction = branch_history_buffer[idx][1];
            
            $fwrite(file, "%4d,    %1b,    0x%h     0x%08h          %0s            %1b", 
                    idx, valid, BTB_tag[idx], BTB[idx], bht_state, prediction);
            
            // Add hit indicator for current IF access
            if (idx == if_index) begin
                $fwrite(file, " <-- IF_HIT(%b)", BTB_hit);
            end
            
            // Add hit indicator for current EX access  
            if (idx == ex_index) begin
                $fwrite(file, " <-- EX_UPDATE");
            end
            
            $fwrite(file, "\n");
        end
    end
endfunction

`endif

endmodule