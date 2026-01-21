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
    output [DATA_WIDTH-1:0]    itlb_data_o,    // The full PTE
    output [31:0]              pa_pc_o
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

    always @(posedge clk_i) begin
        if (rst_i) begin
            for (i = 0; i < ITLB_ENTRIES; i = i + 1) begin
                valid_bit[i] <= 1'b0;
                tag_arr[i]   <= {TAG_SIZE{1'b0}};
                data_arr[i]  <= {DATA_WIDTH{1'b0}};
            end
            // valid_bit[0] = 1'b1;
            // tag_arr[0] = 'h4000;
            // data_arr[0] = 32'h201040cf;
        end else if (itlb_wr_en_i) begin
            // Write using bits extracted from RS1 and RS2
            valid_bit[wr_index] <= 1'b1;
            tag_arr[wr_index]   <= wr_tag;
            data_arr[wr_index]  <= rs2_i; // Store full RS2 content (PTE)
        end
    end


    wire [TAG_SIZE-1:0]   stored_tag;
    wire                  stored_valid;
    wire [21:0] ppn;


    assign stored_valid   = valid_bit[lookup_index];
    assign stored_tag     = tag_arr[lookup_index];
    assign itlb_data_o    = data_arr[lookup_index];
    assign ppn = itlb_data_o[31:10];
    assign itlb_miss_o    = ((~stored_valid) || (stored_tag != lookup_tag)) && execution_mode_i == `U_MODE;
    assign pa_pc_o = (execution_mode_i == `S_MODE) ? pc_i : //If Supervisor, Stop Translation
                      {ppn,pc_i[11:0]};

`ifdef CORE_VERBOSITY
    function void itlb_trace_log(int file);
    integer idx;
    
    // 1. Log the current Interface State (Lookup and Write status)
    // We log pc_i (lookup source), the extracted index/tag, and the result (miss/hit).
    // We also log write signals (rs1, rs2) to see updates happening in real-time.
    $fwrite(file, "\nTime: %1t, ITLB, PC: %08h, L_Idx: %3d, L_Tag: %x, Miss: %b, WrEn: %b, WrAddr: %08h, WrData: %08h", 
            $time, 
            pc_i, 
            lookup_index, 
            lookup_tag, 
            itlb_miss_o, 
            itlb_wr_en_i, 
            rs1_i, 
            rs2_i
    );

    // 2. Log the Array Contents (controlled by Verbosity)
    if(`CORE_VERBOSITY >= 500) begin
      $fwrite(file, "\n\tITLB Array Content Dump:");
      // Header for the table
      // We display the stored Tag and the Data (PTE)
      $fwrite(file, "\n\tIndex \t V \t Tag  \t\t PTE Content (PPN+Flags)");
      $fwrite(file, "\n\t-----------------------------------------------------");
      
      for (idx = 0; idx < ITLB_ENTRIES; idx = idx + 1) begin  
        // Formatting:
        // Index: Decimal
        // Valid: Binary
        // Tag: Hex (sized to TAG_SIZE)
        // Data: Hex (32-bit PTE)
        $fwrite(file, "\n\t%3d \t %1b \t 0x%x \t 0x%08h", 
                idx, 
                valid_bit[idx], 
                tag_arr[idx], 
                data_arr[idx]
        );
      end
      $fwrite(file, "\n");
    end
  endfunction
`endif
endmodule