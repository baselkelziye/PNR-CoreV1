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
    input                    i_alloc_is_store,
    output [3:0]             o_alloc_tag,  
    output                   o_rob_full,
    input i_sb_drain_done,

    // --- Forwarding Signals (Reading values before commit) ---
    input [3:0]              i_rs1_rob_tag, 
    input [3:0]              i_rs2_rob_tag, 
    output                   o_rs1_valid,   
    output                   o_rs2_valid,
    output                   o_rs1_busy,
    output                   o_rs2_busy,
    output [31:0]            o_rs1_value,
    output [31:0]            o_rs2_value,

    // --- Common Data Bus (CDB) Interface ---
    // This is the output of your Arbiter
    input                    i_cdb_valid,  // Replaces i_alu_done
    input [3:0]              i_cdb_tag,    // Replaces i_alu_tag
    input [DATA_WIDTH-1:0]   i_cdb_result, // Replaces i_alu_result
    input                    i_cdb_exc,    // Replaces i_alu_exc
    input [31:0]             i_cdb_scause,
    input [31:0]             i_cdb_stval,
    input                    i_cdb_branch,
    input                    i_cdb_sret,
    input [31:0]             i_cdb_branch_address,
    input [11:0]             i_cdb_csr_addr,
    input                    i_cdb_csr_wr,
    input [31:0]             i_cdb_rs1,
    input [31:0]             i_cdb_rs2,
    input                    i_cdb_itlb_wr_en,
    input                    i_cdb_dtlb_wr_en,
    input                    i_cdb_unconditional_branch,

    // --- Interface with Architectural Register File (Commit) ---
    output reg               o_commit_we,   
    output reg [ADDR_WIDTH-1:0] o_commit_rd,   
    output reg [DATA_WIDTH-1:0] o_commit_data, 
    output reg [31:0]        o_commit_pc,   
    output reg               o_commit_valid,
    output reg [3:0]         o_commit_rob_tag,
    output reg               o_commit_csr_wr_en,
    output reg [11:0]        o_commit_csr_addr,
    output reg [31:0]        o_commit_rs1,
    output reg [31:0]        o_commit_rs2,
    output reg               o_commit_itlb_wr_en,
    output reg               o_commit_dtlb_wr_en,
    output reg [31:0]        rob_commit_instr_o,
    output                   o_flush, //Exception or Mispredict
    output                   o_exception,
    output                   o_sret,
    output [31:0]            o_flush_pc,
    output [31:0]            o_scause_rob,
    output [31:0]            o_stval_rob,
    output [31:0]            o_instr_pc,
    output                   o_rob_sb_drain
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
    reg                  is_store_array[0:ROB_SIZE-1];
    reg [31:0]           scause_array[0:ROB_SIZE-1];
    reg [31:0]           stval_array [0:ROB_SIZE-1];
    reg                  branch_array[0:ROB_SIZE-1];
    reg                  sret_array[0:ROB_SIZE-1];
    reg [31:0]           branch_address[0:ROB_SIZE-1];
    reg [11:0]           csr_addr_array[0:ROB_SIZE-1];
    reg                  csr_wr_array[0:ROB_SIZE-1];
    reg [31:0]           rs1_array[0:ROB_SIZE-1];
    reg [31:0]           rs2_array[0:ROB_SIZE-1];
    reg                  itlb_wr_en[0:ROB_SIZE-1];
    reg                  dtlb_wr_en[0:ROB_SIZE-1];
    reg                  unconditional_branch[0:ROB_SIZE-1];

    // --- ALLOCATION LOGIC ---
    assign o_rob_full = (busy_array[tail] == 1'b1);
    assign o_alloc_tag = tail;

    integer i;
    always @(posedge i_clk) begin
        if (i_rst) begin
            tail <= 0;
            for (i = 0; i < ROB_SIZE; i = i + 1) begin
                busy_array[i]  <= 0;
                valid_array[i] <= 0;
                sret_array[i]  <= 0;
                is_store_array[i] <= 0;
                exc_array[i] <= 0;
                pc_array[i] <= 0;
                instr_array[i] <= 0;
                csr_addr_array[i] <= 0;
                csr_wr_array[i] <= 0;
                rs1_array[i] <= 0;
                rs2_array[i] <= 0;
                itlb_wr_en[i] <= 1'b0;
                dtlb_wr_en[i] <= 1'b0;
                unconditional_branch[i] <= 1'b0;
            end
        end else if(o_flush | o_exception | o_sret) begin
            tail <= 0;
            for (i = 0; i < ROB_SIZE; i = i + 1) begin
                busy_array[i]  <= 0;
                valid_array[i] <= 0;
                sret_array[i]  <= 0; 
                is_store_array[i] <= 0;
                exc_array[i] <= 0;
                pc_array[i] <= 0;
                instr_array[i] <= 0;
                csr_addr_array[i] <= 0;
                csr_wr_array[i] <= 0;
                rs1_array[i] <= 0;
                rs2_array[i] <= 0;
                itlb_wr_en[i] <= 1'b0;
                dtlb_wr_en[i] <= 1'b0;
                unconditional_branch[i] <= 1'b0;
            end
            // tail <= head + 1'b1; //Reset Pointers, Since it circular 
        end else if (i_alloc_en && !o_rob_full) begin
            dst_array[tail]   <= i_alloc_rd;
            we_array[tail]    <= i_alloc_we;
            pc_array[tail]    <= i_alloc_pc;
            instr_array[tail] <= i_alloc_instr;
            is_store_array[tail]    <= i_alloc_is_store;
            busy_array[tail]  <= 1'b1;
            valid_array[tail] <= 1'b0; // Clear valid on new allocation
            exc_array[tail]   <= 1'b0; // Clear exception on new allocation
            scause_array[tail] <= '0;
            stval_array[tail] <= '0;
            branch_array[tail] <= 1'b0;
            sret_array[tail]  <= 0; 
            csr_addr_array[tail] <= 0;
            csr_wr_array[tail] <= 1'b0;
            rs1_array[tail] <= 0; 
            rs2_array[tail] <= 0;
            itlb_wr_en[tail] <= 1'b0;
            dtlb_wr_en[tail] <= 1'b0;
            unconditional_branch[tail] <= 1'b0;
            tail <= tail + 1'b1;

        end 
        if(i_cdb_valid & ~o_flush & ~o_exception & ~o_sret) begin //if we have exception,sret,flush we need to prevet writing
            val_array[i_cdb_tag]   <= i_cdb_result;
            exc_array[i_cdb_tag]   <= i_cdb_exc;
            valid_array[i_cdb_tag] <= 1'b1;
            scause_array[i_cdb_tag] <= i_cdb_scause;
            stval_array[i_cdb_tag] <= i_cdb_stval;
            branch_array[i_cdb_tag] <= i_cdb_branch;
            branch_address[i_cdb_tag] <= i_cdb_branch_address;
            sret_array[i_cdb_tag] <= i_cdb_sret;
            csr_addr_array[i_cdb_tag] <= i_cdb_csr_addr;
            csr_wr_array[i_cdb_tag] <= i_cdb_csr_wr;
            rs1_array[i_cdb_tag] <= i_cdb_rs1;
            rs2_array[i_cdb_tag] <= i_cdb_rs2;
            itlb_wr_en[i_cdb_tag] <= i_cdb_itlb_wr_en;
            dtlb_wr_en[i_cdb_tag] <= i_cdb_dtlb_wr_en;
            unconditional_branch[i_cdb_tag] <= i_cdb_unconditional_branch;
        end

        if(commit_happened) begin //Clear on Commit
            busy_array[head]   <= 1'b0;
            branch_array[head] <= 1'b0;
            sret_array[head]   <= 1'b0;
            valid_array[head]  <= 1'b0;
            exc_array[head]    <= 1'b0;
            csr_wr_array[head] <= 1'b0;
            itlb_wr_en[head] <= 1'b0;
            dtlb_wr_en[head] <= 1'b0;
            unconditional_branch[head] <= 1'b0;
        end
    end


    wire commit_happened;

    assign commit_happened = (busy_array[head] && valid_array[head]) && 
                         ( (exc_array[head] || branch_array[head] || sret_array[head] || unconditional_branch[head]) || // Case 1: Flush
                           (is_store_array[head] && i_sb_drain_done)                  || // Case 2: Store Done
                           (!is_store_array[head] && !exc_array[head] && !branch_array[head] && !sret_array[head]) // Case 3: Regular
                         );
// --- COMMIT LOGIC ---
    always @(posedge i_clk) begin
        if (i_rst) begin
            head             <= 0;
            o_commit_we      <= 0;
            o_commit_rd      <= 0;
            o_commit_data    <= 0;
            o_commit_pc      <= 0;
            o_commit_valid   <= 0;
            o_commit_rob_tag <= 0;
            o_commit_csr_wr_en <= 1'b0;
            o_commit_csr_addr <= '1;
            o_commit_itlb_wr_en <= 1'b0;
            o_commit_dtlb_wr_en <= 1'b0;
        end else begin
            if (busy_array[head] && valid_array[head]) begin
                if (exc_array[head] || (branch_array[head] & ~unconditional_branch[head]) || sret_array[head]) begin
                    head <= 0; 
                    o_commit_we      <= 0;
                    o_commit_rd      <= 0;
                    o_commit_data    <= 0;
                    o_commit_pc      <= 0;
                    o_commit_valid   <= 0;
                    o_commit_rob_tag <= 0;
                    o_commit_csr_wr_en <= 1'b0;
                    o_commit_csr_addr <= '1;
                    o_commit_itlb_wr_en <= 1'b0;
                    o_commit_dtlb_wr_en <= 1'b0;
                    rob_commit_instr_o <= 32'h13;
                end 
                else if (is_store_array[head]) begin //We have valid store, and not exception -> Drain SB
                    //Here also, SB Drain request goes high, check (o_rob_sb_drain)
                    if (i_sb_drain_done) begin //When we recieve this from SB, Then Store is correctly Written
                        head <= head + 1'b1;
                        o_commit_rob_tag <= head;
                        o_commit_pc      <= pc_array[head];
                    end
                end
                else begin
                    o_commit_we      <= we_array[head];
                    o_commit_rd      <= dst_array[head];
                    o_commit_data    <= val_array[head];
                    o_commit_pc      <= pc_array[head];
                    o_commit_valid   <= 1'b1;
                    o_commit_rob_tag <= head;
                    o_commit_csr_wr_en <= csr_wr_array[head];
                    o_commit_csr_addr <= csr_addr_array[head];
                    o_commit_rs1 <= rs1_array[head];
                    o_commit_rs2 <= rs2_array[head];
                    o_commit_itlb_wr_en <= itlb_wr_en[head];
                    o_commit_dtlb_wr_en <= dtlb_wr_en[head];
                    rob_commit_instr_o <= instr_array[head];
                    if(unconditional_branch[head]) begin
                        head <= 0;
                    end else begin
                        head <= head + 1'b1;
                    end
                    

                end
            end else begin
                o_commit_valid <= 1'b0;
                o_commit_we    <= 1'b0;
                o_commit_csr_wr_en <= 1'b0;
                o_commit_itlb_wr_en <= 1'b0;
                o_commit_dtlb_wr_en <= 1'b0;
                rob_commit_instr_o <= 32'h13;
            end
        end
    end

    // --- FORWARDING ASYNC READS ---
    assign o_rs1_valid = valid_array[i_rs1_rob_tag];
    assign o_rs2_valid = valid_array[i_rs2_rob_tag];

    assign o_rs1_busy = busy_array[i_rs1_rob_tag];
    assign o_rs2_busy = busy_array[i_rs2_rob_tag];

    assign o_rs1_value = val_array[i_rs1_rob_tag];
    assign o_rs2_value = val_array[i_rs2_rob_tag];

    assign o_flush     = (busy_array[head] && valid_array[head]) && (branch_array[head] || unconditional_branch[head]);
    assign o_exception = (busy_array[head] && valid_array[head]) && (exc_array[head]   );
    assign o_sret      = (busy_array[head] && valid_array[head]) && (sret_array[head]  );
    assign o_stval_rob     = stval_array[head];
    assign o_scause_rob    = scause_array[head];
    assign o_flush_pc = branch_address[head];
    assign o_instr_pc = pc_array[head];

    assign o_rob_sb_drain = busy_array[head] && valid_array[head] && is_store_array[head] && ~exc_array[head];

`ifdef CORE_VERBOSITY

function rob_trace_log(int i_debug_file);
integer idx;
reg [8*RISCV_DISASM_STRLEN-1:0] disasm_str;// = riscv_disasm(fetched_instruction_id_i, pc_id_i);
$fwrite(i_debug_file, "\nTime: %1t, ROB, i_alloc_en: %b, o_rob_full: %b ",$time, i_alloc_en,o_rob_full);
$fwrite(i_debug_file, "\n\tROB Content Dump (Head: %0d, Tail: %0d)", head, tail);
        // Table Header
        $fwrite(i_debug_file, "\nIdx  B V \tExp UB SRET STORE CSRWR  Dest  CSR  Value       PC          scause       stval     branch    branch_addr   \t Instruction \t Ptr");
        $fwrite(i_debug_file, "\n\t---------------------------------------------------------------------------------------");
        
        for (idx = 0; idx < ROB_SIZE; idx = idx + 1) begin
            disasm_str = riscv_disasm(instr_array[idx], pc_array[idx]);
            $fwrite(i_debug_file, "\n%3d  %1b %1b \t %1b\t %1b  %1b    %1b      %1b    %d   0x%04d 0x%08h  0x%08h   0x%08h   0x%08h    %b     0x%08h       %0s", 
                idx, //3d
                busy_array[idx], //b 
                valid_array[idx], //b
                exc_array[idx], //b 
                unconditional_branch[idx],
                sret_array[idx], //b
                is_store_array[idx], //b
                csr_wr_array[idx],
                dst_array[idx],  //d
                csr_addr_array[idx],
                val_array[idx],  //08h
                pc_array[idx],
                scause_array[idx],
                stval_array[idx],
                branch_array[idx],
                branch_address[idx],
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