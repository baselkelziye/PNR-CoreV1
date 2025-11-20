module l1_icache_controller(
    input clk_i,
    input rst_i,
    input icache_fill_done_i,
    output icache_fill_stall_o,
    output icache_fill_line_o,
    output icache_fill_req_o,
    input icache_hit_i
);

localparam [1:0] I_IDLE     = 2'b00,
                 I_ALLOCATE = 2'b01;

reg [1:0] icache_state_reg, icache_state_next;
reg icache_fill_req_reg, icache_fill_req_next;
reg icache_stall_reg, icache_stall_next;
reg icache_fill_line;
always @(posedge clk_i, posedge rst_i) begin
    if(rst_i) begin
        icache_state_reg       <= I_IDLE;
        icache_fill_req_reg  <= 1'b0;
        icache_stall_reg       <= 1'b0;
    end else begin
        icache_state_reg      <= icache_state_next;
        icache_fill_req_reg <= icache_fill_req_next;
        icache_stall_reg      <= icache_stall_next;
    end
end

always @(*) begin
    icache_state_next = icache_state_reg;
    icache_fill_req_next = icache_fill_req_reg;
    icache_stall_next = icache_stall_reg;
    icache_fill_line = 1'b0;
    case (icache_state_reg)
        I_IDLE: begin
            if(~icache_hit_i) begin //If we have a Cache Miss
                icache_state_next = I_ALLOCATE;
                icache_fill_req_next = 1'b1;
                icache_stall_next = 1'b1;
            end
        end
        I_ALLOCATE: begin
            icache_fill_req_next = 1'b0;
            if(~icache_fill_req_reg & icache_fill_done_i) begin
                icache_fill_line = 1'b1;
            end
        end
        default: begin
            icache_state_next      = I_IDLE;
            icache_fill_req_next = 1'b0;
        end
    endcase
end

assign icache_fill_stall_o = icache_stall_next;
assign icache_fill_line_o = icache_fill_line;
assign icache_fill_req_o  = icache_fill_req_reg;

endmodule