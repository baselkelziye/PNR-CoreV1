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
    input [INSTRUCTION_WIDTH-1-2:0] icache_rd_addr_i
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
    case (mem_state_reg)
        IDLE: begin
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
//make its parameterizable?
wire [30:0] icache_rd_addr;
wire [30:0] dcache_rd_addr;
wire [30:0] dcache_wr_addr;

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

endmodule