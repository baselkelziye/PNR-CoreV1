`timescale 1ns / 1ps

module itlb
#(
    parameter ITLB_ENTRIES        = 32,            // Number of TLB ITLB_ENTRIES (Power of 2)
    parameter DATA_WIDTH     = 32,            // Width of PTE (PPN + Flags)
    
    // Sv32 Address Geometry
    localparam OFFSET_WIDTH  = 12,            // 4KB Page Offset (Bits 11:0)
    localparam INDEX_BITS    = $clog2(ITLB_ENTRIES),
    
    // Calculated Bit Ranges
    // VPN is bits [31:12]. 
    // We split VPN into Tag (Upper) and Index (Lower).
    localparam INDEX_START   = OFFSET_WIDTH,
    localparam INDEX_END     = INDEX_START + INDEX_BITS - 1,
    localparam TAG_START     = INDEX_END + 1,
    localparam TAG_END       = 31,
    localparam TAG_SIZE      = TAG_END - TAG_START + 1
)
(
    input                      clk_i,
    input                      rst_i,
    //Write Signals
    input                      itlb_wr_en_i,
    input [31:0]               rs1_i,         // The Virtual Address
    input [31:0]               rs2_i,         // The PTE Content (Value)
    input [1:0]                execution_mode_i,
    //Lookup signals
    input [31:0]               pc_i,          
    output                     itlb_miss_o,  
    output [DATA_WIDTH-1:0]    itlb_data_o    // The full PTE
);


    wire [INDEX_BITS-1:0] lookup_index;
    wire [TAG_SIZE-1:0]   lookup_tag;
    
    assign lookup_index = pc_i[INDEX_END : INDEX_START];
    assign lookup_tag   = pc_i[TAG_END   : TAG_START];


    wire [INDEX_BITS-1:0] wr_index;
    wire [TAG_SIZE-1:0]   wr_tag;
    
    assign wr_index     = rs1_i[INDEX_END : INDEX_START];
    assign wr_tag       = rs1_i[TAG_END   : TAG_START];
    reg [TAG_SIZE-1:0]    tag_arr   [0:ITLB_ENTRIES-1];
    reg [DATA_WIDTH-1:0]  data_arr  [0:ITLB_ENTRIES-1];
    reg                   valid_bit [0:ITLB_ENTRIES-1];

    integer i;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            for (i = 0; i < ITLB_ENTRIES; i = i + 1) begin
                valid_bit[i] <= 1'b0;
                tag_arr[i]   <= {TAG_SIZE{1'b0}};
                data_arr[i]  <= {DATA_WIDTH{1'b0}};
            end
        end else if (itlb_wr_en_i) begin
            // Write using bits extracted from RS1 and RS2
            valid_bit[wr_index] <= 1'b1;
            tag_arr[wr_index]   <= wr_tag;
            data_arr[wr_index]  <= rs2_i; // Store full RS2 content (PTE)
        end
    end


    wire [TAG_SIZE-1:0]   stored_tag;
    wire                  stored_valid;


    assign stored_valid   = valid_bit[lookup_index];
    assign stored_tag     = tag_arr[lookup_index];
    assign itlb_data_o    = data_arr[lookup_index];
    assign itlb_miss_o    = ((~stored_valid) || (stored_tag != lookup_tag)) && execution_mode_i == `U_MODE;

endmodule