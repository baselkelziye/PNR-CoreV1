module RAM #
(
    parameter I_ENTRIES = 32,
    parameter I_WORDS_PER_LINE = 4,
    parameter INSTRUCTION_WIDTH = 32
)
(
    input clk_i,
    input rst_i,

    //icache interface
    input icache_fill_req_i,
    output icache_fill_done_o,
    output [I_WORDS_PER_LINE-1:0][INSTRUCTION_WIDTH-1:0] icache_line_fill_data_o,
    input [INSTRUCTION_WIDTH-1-2:0] icache_rd_addr_i,
    input branching_i
);

localparam MEM_SIZE = 32'h200000;  // 16 KB
localparam IMEM_BASE = 32'h80000000;
localparam [2:0] IDLE = 3'b000,
                 ICACHE_READ_WORD  = 3'b001,
                 ICACHE_READ_DONE  = 3'b010,
                 DCACHE_SERVE = 3'b011,
                 DCACHE_DONE  = 3'b100;


reg [7:0] MEMORY[0:MEM_SIZE-1];
reg [I_WORDS_PER_LINE-1:0] icache_word_counter_reg, icache_word_counter_next;
reg icache_word_rd_en;
reg icache_rd_done_reg, icache_rd_done_next;
reg [2:0] mem_state_reg,mem_state_next;
reg [INSTRUCTION_WIDTH-1:0] icache_line_tmp[I_WORDS_PER_LINE-1:0];

initial begin
    $readmemh("artifacts/program_test.hex", MEMORY);
    // $readmemh("/home/bkelziye/Desktop/PNR-CoreV1/tests/cocotb/machine_codes/basel_bubblesort.hex", MEMORY);
        // $readmemh("/home/bkelziye/Desktop/PNR-CoreV1/tests/performance_test/machine_codes/matrix_mul_small.hex", MEMORY);


end

always @(posedge clk_i, posedge rst_i) begin
    if(rst_i) begin
        mem_state_reg <= IDLE;
        icache_word_counter_reg <= '0;
        icache_rd_done_reg      <= 1'b0;
    end else begin
        mem_state_reg <= mem_state_next;
        icache_word_counter_reg <= icache_word_counter_next;
        icache_rd_done_reg      <= icache_rd_done_next;
    end
end
//To increase code readability i embedded the memory controller here

always @* begin
    mem_state_next = mem_state_reg;
    icache_word_counter_next = icache_word_counter_reg;
    icache_word_rd_en  = 1'b0;
    icache_rd_done_next = 1'b0;
    if(branching_i) begin
        mem_state_next = IDLE;
        icache_rd_done_next = 1'b0;
        icache_word_counter_next = '0;
    end else begin
    case (mem_state_reg)
        IDLE: begin
            icache_word_counter_next = '0;
            if(icache_fill_req_i) begin
                mem_state_next = ICACHE_READ_WORD;
            end
        end
        ICACHE_READ_WORD: begin
            if(icache_word_counter_reg == I_WORDS_PER_LINE) begin
                icache_word_rd_en = 1'b0;
                mem_state_next = ICACHE_READ_DONE;
            end else begin
                icache_word_rd_en = 1'b1;
                icache_word_counter_next  = icache_word_counter_reg  + 4'b1; 
            end
        end
        ICACHE_READ_DONE: begin
            icache_rd_done_next = 1'b1; //See if i can Move this to Upper state
            mem_state_next = IDLE;
        end
        default:  begin
            mem_state_next = IDLE;
            icache_rd_done_next = 1'b0;
            icache_word_counter_next = '0;
        end
    endcase
end
end
//make its parameterizable?
wire [30:0] icache_rd_addr;
wire [30:0] dcache_rd_addr;
wire [30:0] dcache_wr_addr;
wire [INSTRUCTION_WIDTH-1-2:0] icache_rd_block_addr;
assign icache_rd_block_addr = {icache_rd_addr_i[29:2],2'b00};
     

assign icache_rd_addr = icache_rd_block_addr + icache_word_counter_reg;

//READ Address should be Multiplexed by arbitration logic
always @(posedge clk_i) begin
    if(icache_word_rd_en) begin
        icache_line_tmp[icache_word_counter_reg][7:0]   <= MEMORY[{icache_rd_addr[29:0],2'b00}];
        icache_line_tmp[icache_word_counter_reg][15:8]  <= MEMORY[{icache_rd_addr[29:0],2'b01}];
        icache_line_tmp[icache_word_counter_reg][23:16] <= MEMORY[{icache_rd_addr[29:0],2'b10}];
        icache_line_tmp[icache_word_counter_reg][31:24] <= MEMORY[{icache_rd_addr[29:0],2'b11}];
    end
end

for(genvar i =0; i < I_WORDS_PER_LINE; i = i+1) begin : g_read_icache_data
    assign icache_line_fill_data_o[i] = icache_line_tmp[i];
end

assign icache_fill_done_o = icache_rd_done_reg;

`ifdef CORE_VERBOSITY

reg [127:0] mem_state_str_reg;
reg [127:0] mem_state_str_next;

always @* begin
  case (mem_state_reg)
    IDLE:             mem_state_str_reg = "IDLE";
    ICACHE_READ_WORD: mem_state_str_reg = "ICACHE_READ_WORD";
    ICACHE_READ_DONE: mem_state_str_reg = "ICACHE_READ_DONE";
    DCACHE_SERVE:     mem_state_str_reg = "DCACHE_SERVE";
    DCACHE_DONE:      mem_state_str_reg = "DCACHE_DONE";
    default:          mem_state_str_reg = "UNKNOWN";
  endcase
end

always @* begin
  case (mem_state_next)
    IDLE:             mem_state_str_next = "IDLE";
    ICACHE_READ_WORD: mem_state_str_next = "ICACHE_READ_WORD";
    ICACHE_READ_DONE: mem_state_str_next = "ICACHE_READ_DONE";
    DCACHE_SERVE:     mem_state_str_next = "DCACHE_SERVE";
    DCACHE_DONE:      mem_state_str_next = "DCACHE_DONE";
    default:          mem_state_str_next = "UNKNOWN";
  endcase
end

function void ram_trace_log(int file);
    $fwrite(file, "\nTime: %1t, RAM Controller, state_reg: %0s, state_next: %0s, icache_fill_req_i: %b, icache_fill_done_o: %b", 
            $time, mem_state_str_reg, mem_state_str_next, icache_fill_req_i, icache_fill_done_o);
    $fwrite(file, "\nTime: %1t, RAM Controller, icache_word_counter: %0d/%0d, icache_word_rd_en: %b, icache_rd_addr: 0x%08h",
            $time, icache_word_counter_reg, I_WORDS_PER_LINE, icache_word_rd_en, {icache_rd_addr_i,2'b00});
    
    if (`CORE_VERBOSITY >= 600) begin
        case (mem_state_reg)
            IDLE: begin
                if (icache_fill_req_i) begin
                    $fwrite(file, "\nTime: %1t, RAM Controller -> ICache fill request received, starting read at address 0x%08h", 
                            $time, {icache_rd_addr_i,2'b00});
                end
            end
            ICACHE_READ_WORD: begin
                $fwrite(file, "\nTime: %1t, RAM Controller -> Reading word %0d/%0d from address 0x%08h", 
                        $time, icache_word_counter_reg + 1, I_WORDS_PER_LINE, 
                        {icache_rd_addr_i, 2'b00} + (icache_word_counter_reg * 4));
                if (icache_word_rd_en) begin
                    $fwrite(file, "\nTime: %1t, RAM Controller -> Memory access: reading 4 bytes", $time);
                end
            end
            ICACHE_READ_DONE: begin
                $fwrite(file, "\nTime: %1t, RAM Controller -> Cache line fill completed, %0d words read", 
                        $time, I_WORDS_PER_LINE);
                // Log the entire cache line contents in high verbosity
                if (`CORE_VERBOSITY >= 700) begin
                    $fwrite(file, "\nTime: %1t, RAM Controller -> Cache line contents:", $time);
                    for (integer i = 0; i < I_WORDS_PER_LINE; i = i + 1) begin
                        $fwrite(file, " Word%0d: 0x%08h", i, icache_line_fill_data_o[i]);
                    end
                end
            end
        endcase
        
        // Log state transitions
        if (mem_state_reg != mem_state_next) begin
            $fwrite(file, "\nTime: %1t, RAM Controller -> State transition: %0s -> %0s", 
                    $time, mem_state_str_reg, mem_state_str_next);
        end
    end
endfunction

// Helper function to read memory for debugging
function void ram_memory_dump(int file, logic [31:0] start_addr, int num_words);
    // if (`CORE_VERBOSITY >= 800) begin
    //     $fwrite(file, "\nTime: %1t, RAM Memory Dump from address 0x%08h:", $time, start_addr);
    //     for (int i = 0; i < num_words; i = i + 1) begin
    //         logic [31:0] addr = start_addr + (i * 4);
    //         logic [31:0] data = {MEMORY[addr+3], MEMORY[addr+2], MEMORY[addr+1], MEMORY[addr]};
    //         $fwrite(file, "\n  0x%08h: 0x%08h", addr, data);
    //     end
    // end
endfunction

`endif

endmodule