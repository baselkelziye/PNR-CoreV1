`timescale 1ns / 1ps

module MDU(
    input clk_i,
    input rst_i,
    input start_mdu_i,
    input mem_stall_i,
    input mdu_arbiter_stall_i,
    input  [2:0]  MDU_op_i,
    input  [31:0] MDU_op1_i,
    input  [31:0] MDU_op2_i,
    input  [3:0]  i_rob_tag,     // New: Tag from ROB Allocation
    input  [31:0] i_pc,          // New: PC from Dispatch
    
    output [31:0] MDU_result_o,
    output [3:0]  o_mdu_tag,     // New: Tag to CDB
    output [31:0] o_mdu_pc,      // New: PC to CDB for trace/exceptions
    output        mdu_busy_o,
    output        mdu_done_o     // Acts as the valid signal for the CDB
);

    // -----------------------------------------------------
    // 1. Combinational Calculation (Stage 0)
    // -----------------------------------------------------
    reg [31:0] result_comb;
    reg [31:0] quo_res;
    reg [31:0] rem_res;
    reg [63:0] product;
    wire mdu_stall;
    assign mdu_stall = mdu_arbiter_stall_i | mem_stall_i;

    localparam [2:0]
        MUL_FUNCT3    = 3'b000, MULH_FUNCT3   = 3'b001,
        MULHSU_FUNCT3 = 3'b010, MULHU_FUNCT3  = 3'b011,
        DIV_FUNCT3    = 3'b100, DIVU_FUNCT3   = 3'b101,
        REM_FUNCT3    = 3'b110, REMU_FUNCT3   = 3'b111;

    always @(*) begin
        product = 64'b0;
        quo_res = 32'b0;
        rem_res = 32'b0;

        case (MDU_op_i)
            MUL_FUNCT3, MULH_FUNCT3: product = $signed({{32{MDU_op1_i[31]}}, MDU_op1_i}) * $signed({{32{MDU_op2_i[31]}}, MDU_op2_i});
            MULHSU_FUNCT3:           product = $signed({{32{MDU_op1_i[31]}}, MDU_op1_i}) * $unsigned({32'b0, MDU_op2_i});
            MULHU_FUNCT3:            product = $unsigned({32'b0, MDU_op1_i}) * $unsigned({32'b0, MDU_op2_i});
            DIV_FUNCT3:              quo_res = (MDU_op2_i == 0) ? 32'hFFFFFFFF : ((MDU_op1_i == 32'h80000000) && (MDU_op2_i == 32'hFFFFFFFF)) ? 32'h80000000 : $signed(MDU_op1_i) / $signed(MDU_op2_i);
            DIVU_FUNCT3:             quo_res = (MDU_op2_i == 0) ? 32'hFFFFFFFF : $unsigned(MDU_op1_i) / $unsigned(MDU_op2_i);
            REM_FUNCT3:              rem_res = (MDU_op2_i == 0) ? MDU_op1_i : ((MDU_op1_i == 32'h80000000) && (MDU_op2_i == 32'hFFFFFFFF)) ? 32'h00000000 : $signed(MDU_op1_i) % $signed(MDU_op2_i);
            REMU_FUNCT3:             rem_res = (MDU_op2_i == 0) ? MDU_op1_i : $unsigned(MDU_op1_i) % $unsigned(MDU_op2_i);
            default: begin product = 64'b0; quo_res = 32'b0; rem_res = 32'b0; end
        endcase
    end

    always @(*) begin
        case (MDU_op_i)
            MUL_FUNCT3:    result_comb = product[31:0];
            MULH_FUNCT3, MULHSU_FUNCT3, MULHU_FUNCT3: result_comb = product[63:32];
            DIV_FUNCT3, DIVU_FUNCT3: result_comb = quo_res;
            REM_FUNCT3, REMU_FUNCT3: result_comb = rem_res;
            default:       result_comb = 32'b0;
        endcase
    end

    // -----------------------------------------------------
    // 2. 5-Stage Pipeline Registers
    // -----------------------------------------------------
    reg [31:0] pipe_result [0:4];
    reg [3:0]  pipe_tag    [0:4];
    reg [31:0] pipe_pc     [0:4];
    reg        pipe_valid  [0:4];

    // -----------------------------------------------------
    // 3. Shift Logic with Stall Support
    // -----------------------------------------------------
    integer i;
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            for (i = 0; i < 5; i = i + 1) begin
                pipe_valid[i]  <= 1'b0;
                pipe_result[i] <= 32'b0;
                pipe_tag[i]    <= 4'b0;
                pipe_pc[i]     <= 32'b0;
            end
        end else if (!mdu_stall) begin
            // Stage 0: Inject Calculation
            pipe_valid[0]  <= start_mdu_i;
            pipe_tag[0]    <= i_rob_tag;
            pipe_pc[0]     <= i_pc;
            pipe_result[0] <= result_comb;

            // Stages 1 to 4: Shift Forward
            for (i = 1; i < 5; i = i + 1) begin
                pipe_valid[i]  <= pipe_valid[i-1];
                pipe_tag[i]    <= pipe_tag[i-1];
                pipe_pc[i]     <= pipe_pc[i-1];
                pipe_result[i] <= pipe_result[i-1];
            end
        end
    end

    // -----------------------------------------------------
    // 4. Output Logic
    // -----------------------------------------------------
    
    // Busy if any stage is occupied (Simple stall model)
    assign mdu_busy_o   = |{pipe_valid[0], pipe_valid[1], pipe_valid[2], pipe_valid[3], pipe_valid[4]};
    
    // Final stage outputs
    assign mdu_done_o   = pipe_valid[4];
    assign MDU_result_o = pipe_result[4];
    assign o_mdu_tag    = pipe_tag[4];
    assign o_mdu_pc     = pipe_pc[4];

    `ifdef CORE_VERBOSITY

    function void mdu_trace_log(int i_debug_file);
        integer stage_idx;
        // We assume you might want to see the instruction mnemonic. 
        // If you aren't passing the raw instruction through the pipe, you can remove the disasm part.
        reg [8*32-1:0] disasm_str; 
    
        $fwrite(i_debug_file, "\nTime: %1t, MDU Pipeline Trace", $time);
        $fwrite(i_debug_file, "\n\tSignals: start_mdu: %b, mem_stall: %b, mdu_busy: %b, mdu_done: %b", 
                start_mdu_i, mem_stall_i, mdu_busy_o, mdu_done_o);
        
        // Table Header
        $fwrite(i_debug_file, "\n\tStage | V | Tag | Result     | PC         | Instruction");
        $fwrite(i_debug_file, "\n\t-------------------------------------------------------");
    
        for (stage_idx = 0; stage_idx < 5; stage_idx = stage_idx + 1) begin
            // If you carry the 'instr' in your pipeline, use it here. 
            // Otherwise, disasm might not be possible inside the MDU.
            disasm_str = "..."; // Placeholder if instr_array isn't in MDU
    
            $fwrite(i_debug_file, "\n\t  %1d   | %1b | #%0d  | 0x%08h | 0x%08h | %0s",
                stage_idx,
                pipe_valid[stage_idx],
                pipe_tag[stage_idx],
                pipe_result[stage_idx],
                pipe_pc[stage_idx],
                disasm_str
            );
            
            // Add a visual indicator for where the result is currently sitting
            if (stage_idx == 0 && start_mdu_i) 
                $fwrite(i_debug_file, " <-- NEW REQ");
            if (stage_idx == 4 && pipe_valid[4] && !mem_stall_i) 
                $fwrite(i_debug_file, " <-- EXITING");
        end
        $fwrite(i_debug_file, "\n");
    endfunction
    
    `endif

endmodule