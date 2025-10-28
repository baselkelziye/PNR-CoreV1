module MDU(
    input  [2:0]  MDU_op_i,
    input  [31:0] MDU_op1_i,
    input  [31:0] MDU_op2_i,
    output [31:0] MDU_result_o
);

    reg [31:0] result_r;
    reg [31:0] quo_res;
    reg [31:0] rem_res;
    reg [63:0] product;

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
