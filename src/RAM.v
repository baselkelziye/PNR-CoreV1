module RAM #
(
    parameter I_ENTRIES = 32,
    parameter I_WORDS_PER_LINE = 4,
    parameter D_WORDS_PER_LINE = 4,
    parameter INSTRUCTION_WIDTH = 32,
    parameter WORD_WIDTH = 32
)
(
    input logic clk_i,
    input logic rst_i,

    // --- Arbiter Interface (Request Handshake) ---
    input  logic arb_req_valid_i,
    output logic arb_req_ready_o,      // Ready to receive new request (High when IDLE)
    input  logic [29:0] arb_address_i, // Byte address from Arbiter
    // DCache burst write data (e.g., for cache line eviction)
    input  logic [WORD_WIDTH-1:0] dcache_line_evict_mem_i[0:D_WORDS_PER_LINE-1],
    input  logic arb_rd_wr_i,          // 0 = Read, 1 = Write
    input  logic arb_req_id_i,         // 0 = ICache, 1 = DCache
    
    // --- Response Handshake Input (NEW: Driven by Arbiter) ---
    input  logic arb_cache_ready_i,        // Ready signal from the cache currently being served
    
    // --- Handshake Output ---
    output logic ram_data_valid_o,     // High when operation complete (Valid)
    
    // --- Outputs ---
    // Output for ICache line fill (burst read)
    output logic [INSTRUCTION_WIDTH-1:0] icache_line_fill_data_o[0:I_WORDS_PER_LINE-1], 
    // New output for DCache line fill (burst read)
    output logic [WORD_WIDTH-1:0] dcache_line_fill_data_o[0:D_WORDS_PER_LINE-1], 
    
    // --- Control ---
    input logic branching_i,
    input exception_raised_i
);

    // Memory configuration
    localparam MEM_SIZE = 32'h200000;  // 2MB (adjust as needed)
    
    // States
localparam  [2:0]
        IDLE                = 3'b000,
        ICACHE_READ_WORD    = 3'b001,
        ICACHE_READ_DONE    = 3'b010,  // Stalls here, waiting for arb_cache_ready_i
        DCACHE_READ_WORD    = 3'b011,  // DCache Burst Read
        DCACHE_DONE         = 3'b100,  // Stalls here, waiting for arb_cache_ready_i
        DCACHE_WRITE_WORD   = 3'b101;  // DCache Burst Write

    reg [2:0] mem_state_reg, mem_state_next;

    // Memory Array (Byte Addressable)
    reg [7:0] MEMORY[0:MEM_SIZE-1];

    // Internal Signals
    reg [2:0]  icache_word_counter_reg, icache_word_counter_next;
    reg [2:0]  dcache_word_counter_reg, dcache_word_counter_next; // Counter for DCache burst R/W
    reg        icache_word_rd_en;
    reg        dcache_word_wr_en; // Enable for DCache burst write
    reg        dcache_word_rd_en; // Enable for DCache burst read
    reg        op_done_reg, op_done_next;
    
    // Data Registers
    reg [INSTRUCTION_WIDTH-1:0] icache_line_tmp[I_WORDS_PER_LINE-1:0];
    reg [WORD_WIDTH-1:0] dcache_rdata_word[I_WORDS_PER_LINE-1:0]; // Storage for DCache read line

    // Initialization
    initial begin
        // Update path to your hex file
        $readmemh("/home/bkelziye/Desktop/PNR-CoreV1/tests/spike/trap_handler.hex", MEMORY,32'h0000);
        // $readmemh("/home/bkelziye/Desktop/PNR-CoreV1/tests/cocotb/machine_codes/basel_bubblesort.hex", MEMORY,32'h4000);
        // $readmemh("/home/bkelziye/Desktop/PNR-CoreV1/tests/performance_test/machine_codes/buffer_sum.hex", MEMORY,32'h4000);
        // $readmemh("/home/bkelziye/Desktop/PNR-CoreV1/tests/performance_test/machine_codes/mem_copy.hex", MEMORY,32'h4000);
        // $readmemh("/home/bkelziye/Desktop/PNR-CoreV1/tests/performance_test/memory_files/buffer_sum.mem", MEMORY,32'h16000);
        // $readmemh("/home/bkelziye/Desktop/PNR-CoreV1/tests/performance_test/memory_files/buffer_sum.mem", MEMORY,32'h16000);
        // $readmemh("artifacts/program_test.hex", MEMORY, 32'h4000);
        // $readmemh("/home/bkelziye/Desktop/PNR-CoreV1/tests/cocotb/machine_codes/program_test.hex", MEMORY,32'h4000);
        // Note: Second readmemh will overwrite overlapping regions
        // $readmemh("/home/bkelziye/Desktop/PNR-CoreV1/tests/cocotb/machine_codes/trap_handler.hex", MEMORY, 32'h2000);
        
    end

    // --- Sequential Logic: State & Counters ---
    always @(posedge clk_i or posedge rst_i) begin
        if(rst_i) begin
            mem_state_reg           <= IDLE;
            icache_word_counter_reg <= '0;
            dcache_word_counter_reg <= '0;
            op_done_reg             <= 1'b0;
        end else begin
            mem_state_reg           <= mem_state_next;
            icache_word_counter_reg <= icache_word_counter_next;
            dcache_word_counter_reg <= dcache_word_counter_next;
            op_done_reg             <= op_done_next;
        end
    end

    reg [29:0] arb_address_latched;
    reg arb_rd_wr_latched, arb_req_id_latched;

    always @(posedge clk_i, posedge rst_i) begin
        if(rst_i) begin
            arb_address_latched <= '1;
            arb_rd_wr_latched <= 'X;
            arb_req_id_latched <= 'X;
        end else begin
            if(arb_req_valid_i && mem_state_reg == IDLE) begin //Op Starts
                arb_address_latched <= arb_address_i;
                arb_rd_wr_latched   <= arb_rd_wr_i;
                arb_req_id_latched  <= arb_req_id_i;
            end else if(op_done_reg) begin //Clear
                arb_address_latched <= '1;
                arb_rd_wr_latched   <= 'X;
                arb_req_id_latched <= 'X;
            end
        end
    end
    // --- Output Assignments ---
    assign arb_req_ready_o = (mem_state_reg == IDLE);
    // ram_data_valid_o is asserted for one cycle when the cache is ready
    assign ram_data_valid_o    = op_done_reg; 

    // Map ICache line output
    genvar i;
    generate
        for(i = 0; i < I_WORDS_PER_LINE; i++) begin : g_map_icache_out
            assign icache_line_fill_data_o[i] = icache_line_tmp[i];
        end
    endgenerate
    
    // Map DCache line output
    generate
        for(i = 0; i < I_WORDS_PER_LINE; i++) begin : g_map_dcache_out
            assign dcache_line_fill_data_o[i] = dcache_rdata_word[i];
        end
    endgenerate

    // --- Next State Logic ---
    always @* begin
        mem_state_next = mem_state_reg;
        icache_word_counter_next = icache_word_counter_reg;
        dcache_word_counter_next = dcache_word_counter_reg;
        icache_word_rd_en = 1'b0;
        dcache_word_wr_en = 1'b0;
        dcache_word_rd_en = 1'b0; 
        op_done_next = 1'b0;

        // Reset logic on branch (Flush ICache fill if in progress)
        //Even if we are in IDLE, We check so we don't instantiate a Request
        if((branching_i && (mem_state_reg == ICACHE_READ_WORD || mem_state_reg == ICACHE_READ_DONE || mem_state_reg == IDLE)) || exception_raised_i) begin
            mem_state_next = IDLE;
            op_done_next = 1'b0;
            icache_word_counter_next = '0;
        end 
        else begin
            case (mem_state_reg)
                IDLE: begin
                    icache_word_counter_next = '0;
                    dcache_word_counter_next = '0;
                    if(arb_req_valid_i) begin
                        if(arb_req_id_i == 1'b1) begin // DCache Request
                            if (arb_rd_wr_i) begin // Write
                                mem_state_next = DCACHE_WRITE_WORD;
                            end else begin // Read
                                mem_state_next = DCACHE_READ_WORD; 
                            end
                        end else begin
                            // ICache Request
                            mem_state_next = ICACHE_READ_WORD;
                        end
                    end
                end

                // --- ICache Burst Read Logic ---
                ICACHE_READ_WORD: begin
                    if(icache_word_counter_reg == I_WORDS_PER_LINE) begin
                        icache_word_rd_en = 1'b0;
                        mem_state_next = ICACHE_READ_DONE;
                    end else begin
                        icache_word_rd_en = 1'b1;
                        icache_word_counter_next = icache_word_counter_reg + 3'b1; 
                    end
                end

                // --- ICache Response Handshake: Stall until Ready is high ---
                ICACHE_READ_DONE: begin
                    if (arb_cache_ready_i) begin
                        op_done_next = 1'b1; // Assert Valid
                        mem_state_next = IDLE; // Transaction complete
                    end else begin
                        // Stall: Remain in ICACHE_READ_DONE
                        op_done_next = 1'b0; 
                    end
                end

                // --- DCache Burst Read Logic (Multi-cycle) ---
                DCACHE_READ_WORD: begin
                    if(dcache_word_counter_reg == D_WORDS_PER_LINE) begin
                        dcache_word_rd_en = 1'b0;
                        mem_state_next = DCACHE_DONE;
                    end else begin
                        dcache_word_rd_en = 1'b1;
                        dcache_word_counter_next = dcache_word_counter_reg + 3'b1; 
                    end
                end
                
                // --- DCache Burst Write Logic ---
                DCACHE_WRITE_WORD: begin
                    if(dcache_word_counter_reg == I_WORDS_PER_LINE) begin
                        dcache_word_wr_en = 1'b0;
                        mem_state_next = DCACHE_DONE;
                    end else begin
                        dcache_word_wr_en = 1'b1;
                        dcache_word_counter_next = dcache_word_counter_reg + 1; 
                    end
                end

                // --- DCache Response Handshake: Stall until Ready is high ---
                DCACHE_DONE: begin
                    if (arb_cache_ready_i) begin
                        op_done_next = 1'b1; // Assert Valid
                        mem_state_next = IDLE; // Transaction complete
                    end else begin
                        // Stall: Remain in DCACHE_DONE
                        op_done_next = 1'b0;
                    end
                end

                default: begin
                    mem_state_next = IDLE;
                end
            endcase
        end
    end

    // --- Address Calculation ---
    // Note: arb_address_i is a BYTE address [31:0]
    
    wire [29:0] icache_rd_block_addr;
    wire [29:0] icache_rd_addr;
    wire [29:0] dcache_rd_wr_block_addr;
    wire [29:0] dcache_wr_addr;
    wire [29:0] dcache_current_rd_addr; // Current address for the DCache burst read

    // ICache: Extract block start word index (Word Address).
    // Assign icache_rd_block_addr = {arb_address_i[29:2], 2'b00}; // Original
    assign icache_rd_block_addr = {arb_address_latched[29:2],2'b00};
    
    // ICache Read Word Address: Block Base + Word Counter Offset
    assign icache_rd_addr = icache_rd_block_addr + icache_word_counter_reg;

    // DCache Base Word Address: Start of the line transaction (Word Address)
    assign dcache_rd_wr_block_addr = {arb_address_latched[29:2], 2'b00};
    
    // DCache Write Word Address: Base Word Address + Current Word Offset
    assign dcache_wr_addr = dcache_rd_wr_block_addr + dcache_word_counter_reg;
    
    // DCache Read Word Address: Base Word Address + Current Word Offset (for burst)
    assign dcache_current_rd_addr = dcache_rd_wr_block_addr + dcache_word_counter_reg;
    
    // --- Memory Access (Read/Write) ---
    always @(posedge clk_i) begin
        // ICache Read (Burst)
        if(icache_word_rd_en) begin
            // Reconstruct byte address using explicit concatenation
            icache_line_tmp[icache_word_counter_reg][7:0]   <= MEMORY[{icache_rd_addr[29:0], 2'b00}];
            icache_line_tmp[icache_word_counter_reg][15:8]  <= MEMORY[{icache_rd_addr[29:0], 2'b01}];
            icache_line_tmp[icache_word_counter_reg][23:16] <= MEMORY[{icache_rd_addr[29:0], 2'b10}];
            icache_line_tmp[icache_word_counter_reg][31:24] <= MEMORY[{icache_rd_addr[29:0], 2'b11}];
        end

        // DCache Write Burst
        if(dcache_word_wr_en) begin
            // Address concatenation follows user's requested style
            MEMORY[{dcache_wr_addr, 2'b00}] <= dcache_line_evict_mem_i[dcache_word_counter_reg][7:0];
            MEMORY[{dcache_wr_addr, 2'b01}] <= dcache_line_evict_mem_i[dcache_word_counter_reg][15:8];
            MEMORY[{dcache_wr_addr, 2'b10}] <= dcache_line_evict_mem_i[dcache_word_counter_reg][23:16];
            MEMORY[{dcache_wr_addr, 2'b11}] <= dcache_line_evict_mem_i[dcache_word_counter_reg][31:24];
        end
        
        // DCache Burst Read Access (Multi-cycle)
        if(dcache_word_rd_en) begin
            // --- READ (Little Endian) ---
            dcache_rdata_word[dcache_word_counter_reg][7:0]   <= MEMORY[{dcache_current_rd_addr, 2'b00}];
            dcache_rdata_word[dcache_word_counter_reg][15:8]  <= MEMORY[{dcache_current_rd_addr, 2'b01}];
            dcache_rdata_word[dcache_word_counter_reg][23:16] <= MEMORY[{dcache_current_rd_addr, 2'b10}];
            dcache_rdata_word[dcache_word_counter_reg][31:24] <= MEMORY[{dcache_current_rd_addr, 2'b11}];
        end
    end


    // --- Simulation / Verbosity ---
    `ifdef CORE_VERBOSITY
    reg [511:0] mem_state_str_reg;
    reg [511:0] mem_state_str_next;

    // Assign current state string
    always @* begin
      case (mem_state_reg)
        IDLE:               mem_state_str_reg = "IDLE";
        ICACHE_READ_WORD:   mem_state_str_reg = "ICACHE_R_WORD";
        ICACHE_READ_DONE:   mem_state_str_reg = "ICACHE_R_DONE (Wait Ready)";
        DCACHE_READ_WORD:   mem_state_str_reg = "DCACHE_R_WORD"; 
        DCACHE_WRITE_WORD:  mem_state_str_reg = "DCACHE_W_WORD";
        DCACHE_DONE:        mem_state_str_reg = "DCACHE_DONE (Wait Ready)";
        default:            mem_state_str_reg = "UNKNOWN";
      endcase
    end
    
    // Assign next state string
    always @* begin
      case (mem_state_next)
        IDLE:               mem_state_str_next = "IDLE";
        ICACHE_READ_WORD:   mem_state_str_next = "ICACHE_R_WORD";
        ICACHE_READ_DONE:   mem_state_str_next = "ICACHE_R_DONE (Wait Ready)";
        DCACHE_READ_WORD:   mem_state_str_next = "DCACHE_R_WORD"; 
        DCACHE_WRITE_WORD:  mem_state_str_next = "DCACHE_W_WORD";
        DCACHE_DONE:        mem_state_str_next = "DCACHE_DONE (Wait Ready)";
        default:            mem_state_str_next = "UNKNOWN";
      endcase
    end


    function void ram_trace_log(int file);
        integer j;
        $fwrite(file, "\nTime: %1t, RAM, mem_state_str_reg: %0s, mem_state_str_next: %0s",$time,mem_state_str_reg,mem_state_str_next);
    endfunction

    function void memory_dump(int mem_dump_file, int cycle);
    int i;
    $fwrite(mem_dump_file, "Cycle: :%0d\n", cycle);
    $fwrite(mem_dump_file, "  Address \t \t   Word \t \t   Byte0 \t Byte1 \t Byte2 \t Byte3\n");
    for (i = 32'h16000; i < (32'h16000 + 32'h4000); i = i + 4) begin
        // Print each memory location as "address: value"
        $fwrite(mem_dump_file, "0x%h \t \t  0x%h \t \t %h \t   %h \t   %h \t   %h \n", i, {MEMORY[i+3], MEMORY[i+2], MEMORY[i+1], MEMORY[i]}, MEMORY[i], MEMORY[i+1], MEMORY[i+2], MEMORY[i+3]);
    end
endfunction
    `endif

endmodule