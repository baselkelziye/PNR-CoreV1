`timescale 1ns / 1ps

module dtlb
#(
    parameter DTLB_ENTRIES   = 32,            // Number of TLB ENTRIES
    parameter DATA_WIDTH     = 32,            // Width of PTE (PPN + Flags)
    
    // Sv32 Address Geometry (Same as iTLB)
    localparam OFFSET_WIDTH  = 12,            
    localparam INDEX_BITS    = $clog2(DTLB_ENTRIES),
    
    localparam INDEX_START   = OFFSET_WIDTH,
    localparam INDEX_END     = INDEX_START + INDEX_BITS - 1,
    localparam TAG_START     = INDEX_END + 1,
    localparam TAG_END       = 31,
    localparam TAG_SIZE      = TAG_END - TAG_START + 1
)
(
    input                      clk_i,
    input                      rst_i,
    
    // --- Write Signals (dtlb write) ---
    input                      dtlb_wr_en_i,
    input [31:0]               rs1_i,         // Virtual Address (Key)
    input [31:0]               rs2_i,         // PTE Content (Value)
    
    // --- Lookup Signals (Memory Stage) ---
    input [31:0]               alu_result_i,  // The calculated address
    input                      is_load_mem_i,    // 1 if LOAD instruction
    input                      is_store_mem_i,   // 1 if STORE instruction
    input [1:0]                execution_mode_i, // 00=User, 01=Supervisor

    // --- Outputs ---
    output                     load_page_fault_o,  // Cause 13
    output                     store_page_fault_o, // Cause 15
    output [DATA_WIDTH-1:0]    dtlb_data_o,        // The full PTE
    output [31:0]              pa_dtlb_o,           // Physical Address
    output                     dtlb_hit_o
);

    // ----------------------------------------------------------------------
    // 1. Bit Extraction
    // ----------------------------------------------------------------------
    wire [INDEX_BITS-1:0] lookup_index;
    wire [TAG_SIZE-1:0]   lookup_tag;
    
    assign lookup_index = alu_result_i[INDEX_END : INDEX_START];
    assign lookup_tag   = alu_result_i[TAG_END   : TAG_START];

    wire [INDEX_BITS-1:0] wr_index;
    wire [TAG_SIZE-1:0]   wr_tag;
    
    assign wr_index     = rs1_i[INDEX_END : INDEX_START];
    assign wr_tag       = rs1_i[TAG_END   : TAG_START];

    // ----------------------------------------------------------------------
    // 2. Storage Arrays
    // ----------------------------------------------------------------------
    reg [TAG_SIZE-1:0]    tag_arr   [0:DTLB_ENTRIES-1];
    reg [DATA_WIDTH-1:0]  data_arr  [0:DTLB_ENTRIES-1];
    reg                   valid_bit [0:DTLB_ENTRIES-1];

    integer i;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            for (i = 0; i < DTLB_ENTRIES; i = i + 1) begin
                valid_bit[i] <= 1'b0;
                tag_arr[i]   <= {TAG_SIZE{1'b0}};
                data_arr[i]  <= {DATA_WIDTH{1'b0}};
            end
        end else if (dtlb_wr_en_i) begin
            valid_bit[wr_index] <= 1'b1;
            tag_arr[wr_index]   <= wr_tag;
            data_arr[wr_index]  <= rs2_i; 
        end
    end

    // ----------------------------------------------------------------------
    // 3. Lookup Logic
    // ----------------------------------------------------------------------
    wire [TAG_SIZE-1:0]   stored_tag;
    wire                  stored_valid;
    wire [21:0]           ppn;

    assign stored_valid   = valid_bit[lookup_index];
    assign stored_tag     = tag_arr[lookup_index];
    assign dtlb_data_o    = data_arr[lookup_index];
    
    // Extract PPN from PTE [31:10]
    assign ppn            = dtlb_data_o[31:10];

    // ----------------------------------------------------------------------
    // 4. Exception & Permission Logic
    // ----------------------------------------------------------------------
    wire tlb_hit;
    wire pte_read_ok;
    wire pte_write_ok;

    // Hit Logic: Valid Bit is 1 AND Tags Match
    assign tlb_hit = stored_valid && (stored_tag == lookup_tag);

    // Permission Bits in Sv32: R=Bit 1, W=Bit 2
    assign pte_read_ok  = dtlb_data_o[1]; 
    assign pte_write_ok = dtlb_data_o[2];

    // --- FAULT GENERATION ---
    // Only generate faults in USER MODE (U_MODE). 
    // Supervisor Mode bypasses translation.
    
    wire is_u_mode = (execution_mode_i == 2'b00); // Assuming `U_MODE is 0

    // Load Fault: (U-Mode AND Reading) AND (Miss OR Permission Fail)
    assign load_page_fault_o = is_u_mode && is_load_mem_i && 
                               ( !tlb_hit || !pte_read_ok );

    // Store Fault: (U-Mode AND Writing) AND (Miss OR Permission Fail)
    assign store_page_fault_o = is_u_mode && is_store_mem_i && 
                                ( !tlb_hit || !pte_write_ok );

    // ----------------------------------------------------------------------
    // 5. Physical Address Construction
    // ----------------------------------------------------------------------
    // If Supervisor: Direct Map (PA = VA).
    // If User:       Translated Map (PA = {PPN, Offset}).
    assign pa_dtlb_o = (execution_mode_i == 2'b01) ? alu_result_i : 
                        {ppn, alu_result_i[11:0]};

    assign dtlb_hit_o = tlb_hit || (execution_mode_i == 2'b01); //Always hit on S-mode

    // ----------------------------------------------------------------------
    // 6. Trace Log (Verbosity)
    // ----------------------------------------------------------------------
    `ifdef CORE_VERBOSITY
    function void dtlb_trace_log(int file);
    integer idx;
    
    // 1. Log the current Interface State (Lookup and Write status)
    // Triggers on: Load, Store, or TLB Write
    if (is_load_mem_i || is_store_mem_i || dtlb_wr_en_i) begin
        $fwrite(file, "\nTime: %1t, DTLB, VA: %08h, L_Idx: %3d, L_Tag: %x, Mode: %b, Rd: %b, Wr: %b, Hit: %b, L_Fault: %b, S_Fault: %b, WrEn: %b, WrAddr: %08h, WrData: %08h", 
                $time, 
                alu_result_i,       // Virtual Address being looked up
                lookup_index,       // Extracted Index
                lookup_tag,         // Extracted Tag
                execution_mode_i,   // Privilege Mode (00=User, 01=Supervisor)
                is_load_mem_i,      // Load Enable
                is_store_mem_i,     // Store Enable
                dtlb_hit_o,         // Final Hit Signal (Valid PA available)
                load_page_fault_o,  // Load Fault Status
                store_page_fault_o, // Store Fault Status
                dtlb_wr_en_i,       // Write Enable
                rs1_i,              // Write Address (VA from rs1)
                rs2_i               // Write Data (PTE from rs2)
        );
    end

    // 2. Log the Array Contents (controlled by Verbosity)
    if(`CORE_VERBOSITY >= 500) begin
      $fwrite(file, "\n\tDTLB Array Content Dump:");
      // Header for the table
      $fwrite(file, "\n\tIndex \t V \t Tag  \t\t PTE Content (PPN+Flags)");
      $fwrite(file, "\n\t-----------------------------------------------------");
      
      for (idx = 0; idx < DTLB_ENTRIES; idx = idx + 1) begin  
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