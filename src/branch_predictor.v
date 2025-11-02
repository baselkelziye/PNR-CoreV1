module branch_predictor
#(parameter N = 10)(
    input clk_i,
    input rst_i,

    input [31:0] pc_i,
    input [31:0] pc_ex_i,
    input [31:0] btb_address_value_i, //ALU res from EX
    input update_btb_address_i,

    //2Bit Predictor Signals
    input increment_counter,
    input decrement_counter,


    output [31:0] btb_fetched_address_o,
    output branch_is_taken
    
);

localparam [1:0]

  STRONGLY_NOT_TAKEN = 2'b00,
  WEAKLY_NOT_TAKEN   = 2'b01,
  WEAKLY_TAKEN       = 2'b10,
  STRONGLY_TAKEN     = 2'b11;


localparam BTB_TAG_SIZE = 32 - (N + 2);
reg [31:0]              BTB[2**N-1:0];
reg                     BTB_valid[2**N-1:0];
reg [BTB_TAG_SIZE-1:0]  BTB_tag[2**N-1:0];
integer i;
wire BTB_hit;
wire [1:0] if_pc_counter_2bit_counter, ex_pc_2bit_counter;
reg [1:0] branch_history_buffer[2**N-1:0]; 

assign ex_pc_2bit_counter = branch_history_buffer[pc_ex_i[N:2]];
assign if_pc_counter_2bit_counter = branch_history_buffer[pc_i[N:2]];


always @(posedge clk_i, posedge rst_i) begin
    if(rst_i) begin
        for(i = 0; i < 2**N; i = i+1) begin
            BTB[i] = 32'h0;
            BTB_tag[i] = '0;
        end
    end else begin
        if(update_btb_address_i) begin
            BTB[pc_ex_i[N:2]] <= btb_address_value_i;
            BTB_tag[pc_ex_i[N:2]] <= pc_ex_i[31:N+1];
        end
    end
end


always @(posedge clk_i, posedge rst_i)
begin //might need to add IF branch instr
  if(rst_i)
    for(i = 0; i < 2**N; i = i + 1)
        branch_history_buffer[i] = STRONGLY_NOT_TAKEN;
  else
  begin
    if(ex_pc_2bit_counter != STRONGLY_TAKEN && increment_counter)
        branch_history_buffer[pc_ex_i[N:2]] <= branch_history_buffer[pc_ex_i[N:2]] + 2'b1;
    else if( ex_pc_2bit_counter != STRONGLY_NOT_TAKEN && decrement_counter)
        branch_history_buffer[pc_ex_i[N:2]] <= branch_history_buffer[pc_ex_i[N:2]] - 2'b1;
  end
end

assign btb_fetched_address_o = BTB[pc_i[N:2]];
assign BTB_hit = BTB_tag[pc_i[N:2]] == pc_i[31:N+1];
assign branch_is_taken = if_pc_counter_2bit_counter[1] & BTB_hit;



endmodule