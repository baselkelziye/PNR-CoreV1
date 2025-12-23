module rob #(
    parameter ROB_SIZE = 16,
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5
)(
    input i_clk,
    input i_rst,

    // --- Interface with Decode (Allocation) ---
    input                    i_alloc_en,   
    input [ADDR_WIDTH-1:0]   i_alloc_rd,   
    input                    i_alloc_we,   
    input [31:0]             i_alloc_pc,   
    input [31:0]             i_alloc_instr,
    output [3:0]             o_alloc_tag,  
    output                   o_rob_full,

    // --- Forwarding Signals (Reading values before commit) ---
    input [3:0]              i_rs1_rob_tag, 
    input [3:0]              i_rs2_rob_tag, 
    output                   o_rs1_valid,   
    output                   o_rs2_valid,
    output [31:0]            o_rs1_value,
    output [31:0]            o_rs2_value,

    // --- Common Data Bus (CDB) Interface ---
    // This is the output of your Arbiter
    input                    i_cdb_valid,  // Replaces i_alu_done
    input [3:0]              i_cdb_tag,    // Replaces i_alu_tag
    input [DATA_WIDTH-1:0]   i_cdb_result, // Replaces i_alu_result
    input                    i_cdb_exc,    // Replaces i_alu_exc

    // --- Interface with Architectural Register File (Commit) ---
    output reg               o_commit_we,   
    output reg [ADDR_WIDTH-1:0] o_commit_rd,   
    output reg [DATA_WIDTH-1:0] o_commit_data, 
    output reg [31:0]        o_commit_pc,   
    output reg               o_commit_valid,
    output reg [3:0]         o_commit_rob_tag
);

    // Circular Buffer Pointers
    reg [3:0] head;
    reg [3:0] tail;

    // Storage Arrays
    reg [DATA_WIDTH-1:0] val_array   [0:ROB_SIZE-1];
    reg [ADDR_WIDTH-1:0] dst_array   [0:ROB_SIZE-1];
    reg [31:0]           pc_array    [0:ROB_SIZE-1];
    reg [31:0]           instr_array [0:ROB_SIZE-1]; 
    reg                  we_array    [0:ROB_SIZE-1];
    reg                  valid_array [0:ROB_SIZE-1];
    reg                  exc_array   [0:ROB_SIZE-1];
    reg                  busy_array  [0:ROB_SIZE-1];

    // --- ALLOCATION LOGIC ---
    assign o_rob_full = (busy_array[tail] == 1'b1);
    assign o_alloc_tag = tail;

    integer i;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            tail <= 0;
            for (i = 0; i < ROB_SIZE; i = i + 1) begin
                busy_array[i]  <= 0;
                valid_array[i] <= 0;
            end
        end else if (i_alloc_en && !o_rob_full) begin
            dst_array[tail]   <= i_alloc_rd;
            we_array[tail]    <= i_alloc_we;
            pc_array[tail]    <= i_alloc_pc;
            instr_array[tail] <= i_alloc_instr;
            busy_array[tail]  <= 1'b1;
            valid_array[tail] <= 1'b0; // Clear valid on new allocation
            exc_array[tail]   <= 1'b0; // Clear exception on new allocation
            tail <= tail + 1'b1;
        end 
        if(i_cdb_valid) begin // Common Data Bus Write Logic
            val_array[i_cdb_tag]   <= i_cdb_result;
            exc_array[i_cdb_tag]   <= i_cdb_exc;
            valid_array[i_cdb_tag] <= 1'b1;
        end  
        if(busy_array[head] && valid_array[head]) begin //Clear on Commit
            busy_array[head] <= 1'b0;
        end
    end

    // --- COMMON DATA BUS (CDB) WRITE LOGIC ---
    // always @(posedge i_clk) begin
    //     if (i_cdb_valid) begin
    //         val_array[i_cdb_tag]   <= i_cdb_result;
    //         exc_array[i_cdb_tag]   <= i_cdb_exc;
    //         valid_array[i_cdb_tag] <= 1'b1;
    //     end
    // end

    // --- COMMIT LOGIC ---
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            head <= 0;
            o_commit_we    <= 0;
            o_commit_valid <= 0;
        end else begin
            if (busy_array[head] && valid_array[head]) begin
                o_commit_we    <= we_array[head];
                o_commit_rd    <= dst_array[head];
                o_commit_data  <= val_array[head];
                o_commit_pc    <= pc_array[head];
                o_commit_valid <= 1'b1;

                // busy_array[head] <= 1'b0;
                o_commit_rob_tag <= head;
                head <= head + 1'b1;
            end else begin
                o_commit_valid <= 1'b0;
                o_commit_we    <= 1'b0;
            end
        end
    end

    // --- FORWARDING ASYNC READS ---
    assign o_rs1_valid = valid_array[i_rs1_rob_tag];
    assign o_rs2_valid = valid_array[i_rs2_rob_tag];
    assign o_rs1_value = val_array[i_rs1_rob_tag];
    assign o_rs2_value = val_array[i_rs2_rob_tag];

`ifdef CORE_VERBOSITY

function rob_trace_log(int i_debug_file);
integer idx;
reg [8*RISCV_DISASM_STRLEN-1:0] disasm_str;// = riscv_disasm(fetched_instruction_id_i, pc_id_i);
$fwrite(i_debug_file, "\nTime: %1t, ROB, i_alloc_en: %b, o_rob_full: %b ",$time, i_alloc_en,o_rob_full);
$fwrite(i_debug_file, "\n\tROB Content Dump (Head: %0d, Tail: %0d)", head, tail);
        // Table Header
        $fwrite(i_debug_file, "\n\tIdx \t B \t V \t Dest \t Value      \t PC         \t Instruction \t Ptr");
        $fwrite(i_debug_file, "\n\t---------------------------------------------------------------------------------------");
        
        for (idx = 0; idx < ROB_SIZE; idx = idx + 1) begin
            disasm_str = riscv_disasm(instr_array[idx], pc_array[idx]);
            $fwrite(i_debug_file, "\n\t%3d \t %1b \t %1b \t %d \t 0x%08h \t 0x%08h \t   %0s", 
                idx, 
                busy_array[idx], 
                valid_array[idx], 
                dst_array[idx], 
                val_array[idx], 
                pc_array[idx], 
                disasm_str
            );

            // Append pointer information at the end of the line
            if (idx == head && idx == tail)
                $fwrite(i_debug_file, " \t HEAD+TAIL");
            else if (idx == head)
                $fwrite(i_debug_file, " \t HEAD");
            else if (idx == tail)
                $fwrite(i_debug_file, " \t TAIL");
        end
        $fwrite(i_debug_file, "\n");

endfunction

`endif

endmodule