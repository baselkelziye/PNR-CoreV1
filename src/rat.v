module rat #(
    parameter ROB_TAG_WIDTH = 4,
    parameter REG_ADDR_WIDTH = 5
)(
    input i_clk,
    input i_rst,

    // --- Lookup (Decode Stage) ---
    input  [REG_ADDR_WIDTH-1:0] i_rs1_addr,
    input  [REG_ADDR_WIDTH-1:0] i_rs2_addr,
    
    output [ROB_TAG_WIDTH-1:0]  o_rs1_tag,
    output                      o_rs1_in_rob, // High if data is in ROB
    output [ROB_TAG_WIDTH-1:0]  o_rs2_tag,
    output                      o_rs2_in_rob,

    // --- Update (Allocation/Dispatch) ---
    input                       i_alloc_en,
    input  [REG_ADDR_WIDTH-1:0] i_alloc_rd,
    input                       i_alloc_wr_en,
    input  [ROB_TAG_WIDTH-1:0]  i_alloc_tag,

    // --- Retirement (Commit) ---
    input                       i_commit_en,
    input  [REG_ADDR_WIDTH-1:0] i_commit_rd,
    input  [ROB_TAG_WIDTH-1:0]  i_commit_tag
);

    reg [ROB_TAG_WIDTH-1:0] tag_table [0:31];
    reg [31:0]              in_rob_bits; // bitmask for 32 registers

    // 1. Lookup Logic
    assign o_rs1_tag    = tag_table[i_rs1_addr];
    assign o_rs1_in_rob = in_rob_bits[i_rs1_addr];
    
    assign o_rs2_tag    = tag_table[i_rs2_addr];
    assign o_rs2_in_rob = in_rob_bits[i_rs2_addr];

    integer i;
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            in_rob_bits <= 32'b0;
            for (i = 0; i < 32; i = i + 1) tag_table[i] <= 0;
        end else begin
            // 2. Allocation: Update RAT to point to the NEW ROB tag
            if (i_alloc_en && i_alloc_rd != 5'b0) begin
                tag_table[i_alloc_rd]   <= i_alloc_tag;
                in_rob_bits[i_alloc_rd] <= 1'b1;
            end

            // 3. Commitment: If the instruction retiring is the one the RAT points to,
            // mark the register as "back in ARF" (0).
            if (i_commit_en && i_commit_rd != 5'b0) begin
                if (tag_table[i_commit_rd] == i_commit_tag) begin
                    in_rob_bits[i_commit_rd] <= 1'b0;
                end
            end
        end
    end

`ifdef CORE_VERBOSITY
function rat_trace_log(int file);

// Add to rat module
// input integer file

integer idx;
    $fwrite(file,"\nTime: %1t, RAT, i_rs1_addr: %d, o_rs1_tag: %d, o_rs1_in_rob: %b", $time, i_rs1_addr,o_rs1_tag,o_rs1_in_rob);
    $fwrite(file,"\nTime: %1t, RAT, i_rs2_addr: %d, o_rs2_tag: %d, o_rs2_in_rob: %b", $time, i_rs2_addr,o_rs2_tag,o_rs2_in_rob);
    $fwrite(file,"\nTime: %1t, RAT, i_alloc_en: %b, i_alloc_rd: %d, i_alloc_wr_en: %b, i_alloc_tag: %d", $time, i_alloc_en,i_alloc_rd,i_alloc_wr_en,i_alloc_tag);
    
    $fwrite(file, "\n\tRAT (Register Alias Table) Content Dump:");
    $fwrite(file, "\n\tReg \t In_ROB \t ROB_Tag");
    $fwrite(file, "\n\t-------------------------------");
    
    for (idx = 0; idx < 32; idx = idx + 1) begin
        // Only print registers that are actually renamed to save log space, 
        // or print all if you prefer a consistent table.
        if (in_rob_bits[idx]) begin
            $fwrite(file, "\n\tx%2d \t   1    \t   #%0d", 
                    idx, tag_table[idx]);
        end else begin
            $fwrite(file, "\n\tx%2d \t   0    \t   --", idx);
        end
    end
    $fwrite(file, "\n");


endfunction

`endif
endmodule