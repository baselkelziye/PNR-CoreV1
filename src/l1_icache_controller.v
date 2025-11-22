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
                icache_stall_next = 1'b0;
                icache_state_next      = I_IDLE;
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

`ifdef CORE_VERBOSITY

reg [127:0] icache_state_str_reg;
reg [127:0] icache_state_str_next;

always @* begin
  case (icache_state_reg)
    I_IDLE:     icache_state_str_reg = "I_IDLE";
    I_ALLOCATE: icache_state_str_reg = "I_ALLOCATE";
    default:    icache_state_str_reg = "I_UNKNOWN";
  endcase
end

always @* begin
  case (icache_state_next)
    I_IDLE:     icache_state_str_next = "I_IDLE";
    I_ALLOCATE: icache_state_str_next = "I_ALLOCATE";
    default:    icache_state_str_next = "I_UNKNOWN";
  endcase
end

function void icache_controller_trace_log(int file);
    $fwrite(file, "\nTime: %1t, ICache Controller, state_reg: %0s, state_next: %0s, icache_hit_i: %b, icache_fill_stall_o: %b", 
            $time, icache_state_str_reg, icache_state_str_next, icache_hit_i, icache_fill_stall_o);
    $fwrite(file, "\nTime: %1t, ICache Controller, icache_fill_req_o: %b, icache_fill_line_o: %b, icache_fill_done_i: %b",
            $time, icache_fill_req_o, icache_fill_line_o, icache_fill_done_i);
    
    if (`CORE_VERBOSITY >= 600) begin
        case (icache_state_reg)
            I_IDLE: begin
                if (~icache_hit_i) begin
                    $fwrite(file, "\nTime: %1t, ICache Controller -> Cache Miss detected, transitioning to ALLOCATE", $time);
                end else begin
                    $fwrite(file, "\nTime: %1t, ICache Controller -> Cache Hit, staying in IDLE", $time);
                end
            end
            I_ALLOCATE: begin
                if (icache_fill_done_i) begin
                    $fwrite(file, "\nTime: %1t, ICache Controller -> Fill completed, cache line updated, returning to IDLE", $time);
                end else if (icache_fill_req_reg) begin
                    $fwrite(file, "\nTime: %1t, ICache Controller -> Waiting for memory fill to complete", $time);
                end else begin
                    $fwrite(file, "\nTime: %1t, ICache Controller -> Fill request sent, waiting for response", $time);
                end
            end
        endcase
    end
endfunction

`endif


endmodule