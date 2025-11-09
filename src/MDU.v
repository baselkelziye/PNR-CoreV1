module MDU(
    input clk_i,
    input rst_i,
    input start_mdu_i,
    input mem_stall_i,
    input  [2:0]  MDU_op_i,
    input  [31:0] MDU_op1_i,
    input  [31:0] MDU_op2_i,
    output [31:0] MDU_result_o,
    output mdu_busy_o,
    output mdu_done_o
);

    reg [31:0] result_r;
    reg [31:0] quo_res;
    reg [31:0] rem_res;
    reg [63:0] product;

    /*
    Now we can accept only 1 Operation,
    Later I need to see how to Trigger MDU and 1 instruction later
    Operate on ALU, And how to handle consecutive Muls
    */

    /*
    An intresting Case to hae is to have a Cache Stall that exceeds 5 Cycles
    to see if we are able to capture the Result of mul and wait
    */
    reg mdu_busy, mdu_done;
    reg [2:0] mul_counter_reg;
    wire [2:0] mul_counter_next;

    always @(*) begin
        if(rst_i) begin
            mdu_busy = 1'b0;
        end else begin
            if(start_mdu_i & !mdu_done) begin
                mdu_busy = 1'b1;
            end else begin
                mdu_busy = 1'b0;
            end
        end
    end

    always @(posedge clk_i, posedge rst_i) begin
        if(rst_i) begin
            mdu_done <= 1'b0;
        end else if(mul_counter_reg == 3'b101 & ~mem_stall_i) begin
            mdu_done <= 1'b1;
        end else begin
            mdu_done <= 1'b0;
        end
    end

    always @(posedge clk_i, posedge rst_i) begin
        if(rst_i | mdu_done) begin
            mul_counter_reg <= 3'b0;
        end else if(start_mdu_i) begin
            if(mul_counter_reg == 3'b101 & ~mem_stall_i) begin //If we are Done but we have a stall from cache, We need to wait
                mul_counter_reg <= mul_counter_reg;
            end else begin
                mul_counter_reg <= mul_counter_reg + 3'b1;
            end
        end
    end
    // assign mul_counter_next = (mdu_done) ? 3'b0 : 
    //                           (start_mdu_i) ? mul_counter_reg + 3'b1:  mul_counter_reg;

    assign mdu_busy_o = mdu_busy;
    assign mdu_done_o = mdu_done;
    
    // ---------------- Local Parameters ----------------
    localparam [2:0]
        MUL_FUNCT3    = 3'b000,
        MULH_FUNCT3   = 3'b001,
        MULHSU_FUNCT3 = 3'b010,
        MULHU_FUNCT3  = 3'b011,
        DIV_FUNCT3    = 3'b100,
        DIVU_FUNCT3   = 3'b101,
        REM_FUNCT3    = 3'b110,
        REMU_FUNCT3   = 3'b111;

    // ---------------- Main Operation ----------------
    always @(*) begin
        // default values to avoid latch inference
        product = 64'b0;
        quo_res = 32'b0;
        rem_res = 32'b0;

        case (MDU_op_i)
            // -----------------------------------------------------
            // Multiplication Group (explicit 64-bit extensions)
            // -----------------------------------------------------
            MUL_FUNCT3,
            MULH_FUNCT3: begin
                product = $signed({{32{MDU_op1_i[31]}}, MDU_op1_i}) *
                          $signed({{32{MDU_op2_i[31]}}, MDU_op2_i});
            end

            MULHSU_FUNCT3: begin
                product = $signed({{32{MDU_op1_i[31]}}, MDU_op1_i}) *
                          $unsigned({32'b0, MDU_op2_i});
            end

            MULHU_FUNCT3: begin
                product = $unsigned({32'b0, MDU_op1_i}) *
                          $unsigned({32'b0, MDU_op2_i});
            end

            // -----------------------------------------------------
            // Division / Remainder Group
            // -----------------------------------------------------
            DIV_FUNCT3: begin
                // signed division
                if (MDU_op2_i == 0)
                    quo_res = 32'hFFFFFFFF;
                else if ((MDU_op1_i == 32'h80000000) && (MDU_op2_i == 32'hFFFFFFFF))
                    quo_res = 32'h80000000; // overflow
                else
                    quo_res = $signed(MDU_op1_i) / $signed(MDU_op2_i);
            end

            DIVU_FUNCT3: begin
                // unsigned division
                if (MDU_op2_i == 0)
                    quo_res = 32'hFFFFFFFF;
                else
                    quo_res = $unsigned(MDU_op1_i) / $unsigned(MDU_op2_i);
            end

            REM_FUNCT3: begin
                // signed remainder
                if (MDU_op2_i == 0)
                    rem_res = MDU_op1_i;
                else if ((MDU_op1_i == 32'h80000000) && (MDU_op2_i == 32'hFFFFFFFF))
                    rem_res = 32'h00000000; // overflow remainder
                else
                    rem_res = $signed(MDU_op1_i) % $signed(MDU_op2_i);
            end

            REMU_FUNCT3: begin
                // unsigned remainder
                if (MDU_op2_i == 0)
                    rem_res = MDU_op1_i;
                else
                    rem_res = $unsigned(MDU_op1_i) % $unsigned(MDU_op2_i);
            end

            default: begin
                product = 64'b0;
                quo_res = 32'b0;
                rem_res = 32'b0;
            end
        endcase
    end

    // ---------------- Output Selection ----------------
    always @(*) begin
        result_r = 32'b0; // default to prevent latch

        case (MDU_op_i)
            MUL_FUNCT3   : result_r = product[31:0];
            MULH_FUNCT3  : result_r = product[63:32];
            MULHSU_FUNCT3: result_r = product[63:32];
            MULHU_FUNCT3 : result_r = product[63:32];
            DIV_FUNCT3   : result_r = quo_res;
            DIVU_FUNCT3  : result_r = quo_res;
            REM_FUNCT3   : result_r = rem_res;
            REMU_FUNCT3  : result_r = rem_res;
            default      : result_r = 32'b0;
        endcase
    end

    assign MDU_result_o = result_r;

endmodule
