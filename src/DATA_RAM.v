module DATA_RAM
#(
    parameter ADDRESS_WIDTH  = 32,
    parameter DATA_WIDTH     = 32,
    parameter WORDS_PER_LINE = 2,
    localparam BYTE_OFF_BITS = 2,
    localparam WORD_OFF_BITS = $clog2(WORDS_PER_LINE)
)
(
    input clk_i,
    input rst_i,
    input [ADDRESS_WIDTH-1-2:0] wr_data_addr_i,
    input [ADDRESS_WIDTH-1-2:0] rd_data_addr_i,
    input [DATA_WIDTH-1:0] wr_data_i[0:WORDS_PER_LINE-1],

    //Inputs from dcache controller
    input start_ram_write_i,
    input start_ram_read_i,


    output [DATA_WIDTH-1:0] rd_data_o[0:WORDS_PER_LINE-1],
    output ram_wr_done_o,
    output ram_rd_done_o

);

parameter MEM_BASE = 32'h00000000;
parameter MEM_SIZE = 32'h20000; // 2 MB is safe for most RISCOF tests
localparam [2:0] IDLE       = 3'b000,
                 WRITE_WORD = 3'b001,
                 WRITE_DONE = 3'b010,
                 READ_WORD  = 3'b010,
                 READ_DONE  = 3'b011;
`include "encodings.vh"
// (* verilator public_flat_rw *)
  reg [31:0] RAM [0:MEM_SIZE-1];

reg ram_wr_done_reg, ram_wr_done_next;
reg ram_rd_done_reg, ram_rd_done_next;
reg [WORDS_PER_LINE-1:0] word_write_counter_reg, word_write_counter_next;
reg [WORDS_PER_LINE-1:0] word_read_counter_reg,word_read_counter_next;
reg [2:0] ram_state_reg, ram_state_next;
reg write_ram_enable,read_ram_enable;
reg [DATA_WIDTH-1:0] rd_data_word[0:WORDS_PER_LINE-1];

always @(posedge clk_i) begin
    if(rst_i) begin
        ram_state_reg          <= IDLE;
        ram_wr_done_reg   <= 1'b0;
        word_write_counter_reg <= 0;
        word_read_counter_reg  <= 0;
        ram_rd_done_reg <= 1'b0;
    end else begin
        ram_state_reg          <= ram_state_next;
        ram_wr_done_reg   <= ram_wr_done_next;
        word_write_counter_reg <= word_write_counter_next;
        word_read_counter_reg  <= word_read_counter_next;
        ram_rd_done_reg     <= ram_rd_done_next;
    end
end

always @* begin
    ram_state_next          = ram_state_reg;
    word_write_counter_next = word_write_counter_reg;
    word_read_counter_next  = word_read_counter_reg;
    write_ram_enable     = 1'b0;
    read_ram_enable      = 1'b0;
    ram_wr_done_next = 1'b0;
    ram_rd_done_next  = 1'b0;
    case (ram_state_reg)
        IDLE: begin
            if(start_ram_write_i) begin
                word_write_counter_next = 0;
                ram_state_next = WRITE_WORD;
            end else if(start_ram_read_i) begin
                word_read_counter_next  = 0;
                ram_state_next = READ_WORD;
            end
        end
        WRITE_WORD: begin
            if(word_write_counter_reg == WORDS_PER_LINE-1) begin
                write_ram_enable = 1'b0;
                ram_state_next = WRITE_DONE;
            end else begin
                write_ram_enable = 1'b1;
                word_write_counter_next = word_write_counter_reg + 1;
            end
        end
        WRITE_DONE: begin
            ram_wr_done_next = 1'b1;
            ram_state_next       = IDLE;
        end

        READ_WORD: begin
            if(word_read_counter_reg == WORDS_PER_LINE-1) begin
                read_ram_enable = 1'b0;
                ram_state_next  = READ_DONE;
            end else begin
                read_ram_enable = 1'b1;
                word_read_counter_next = word_read_counter_reg + 1;
            end
        end

        READ_DONE: begin
            ram_rd_done_next = 1'b1;
            ram_state_next        = IDLE;
        end

        default:  begin
            ram_wr_done_next = 1'b0;
            ram_rd_done_next  = 1'b0;
            ram_state_next       = IDLE;
            word_write_counter_next = 0;
        end 
    endcase
end

always @(posedge clk_i) begin
    if(write_ram_enable) begin
        RAM[wr_data_addr_i + word_write_counter_reg] <= wr_data_i[word_write_counter_reg];
    end
end

//Read Block
always @(posedge clk_i) begin
    if(read_ram_enable) begin
        rd_data_word[i] <= RAM[rd_data_addr_i + word_read_counter_reg];
    end
end

for(genvar i = 0; i < WORDS_PER_LINE; i = i +1) begin : g_read_ram_data
    assign rd_data_o[i] = rd_data_word[i];
end


//If we have access and not done yet, stall
assign ram_wr_done_o =  ram_wr_done_reg;
assign ram_rd_done_o =  ram_rd_done_reg;

`ifdef CORE_VERBOSITY

reg [127:0] ram_state_str_reg,ram_state_str_next; // enough width to hold your longest string

always @* begin
  case (ram_state_reg)
    IDLE:        ram_state_str_reg = "IDLE";
    WRITE_WORD: ram_state_str_reg = "WRITE_WORD";
    WRITE_DONE:  ram_state_str_reg = "WRITE_DONE";
    default:     ram_state_str_reg = "UNKNOWN";
  endcase
end

always @* begin
  case (ram_state_next)
    IDLE:        ram_state_str_next = "IDLE";
    WRITE_WORD: ram_state_str_next = "WRITE_WORD";
    WRITE_DONE:  ram_state_str_next = "WRITE_DONE";
    default:     ram_state_str_next = "UNKNOWN";
  endcase
end

`endif
function void DATA_RAM_trace_log(int file);
    $fwrite(file,"\nTime: %1t, DATA_RAM, ram_state_reg: %0s, ram_state_next: %0s, start_ram_write_i: %b, start_ram_read_i: %b, ram_wr_done_o: %b, ram_rd_done_o: %b", $time, ram_state_str_reg,ram_state_str_next,start_ram_write_i,start_ram_read_i,ram_wr_done_o,ram_rd_done_o);
endfunction

endmodule