module csr(
    input clk_i,
    input rst_i,

    //CSR Instruction
    input  [11:0] csr_rd_addr_i, // CSR identifier (from decoder)
    input  [11:0] csr_wr_addr_i, // CSR Addrs to be written (from WB)
    input         csr_wr_en_i, //Write for CSRR*/I Instructions
    input  [31:0] csr_wr_value_i, //Write Value to CSR from WB

    //HW Controlled CSR Signals
    input         csr_trap_wr_en_i, //Write When there is Exception (From WB!)
    output [31:0] csr_rd_data_o, // This needs to be assigned from a Reg, Because CSR writes happen atomicaly (Read Value, Write New Value at same time)

    //M level Trap Signals
    
    input [31:0] s_trap_pc_i,
    input [31:0] s_trap_cause_i,
    input [31:0] s_trap_tval,

    output [31:0] s_tvec_o

);


/*MTVEC
3.1.7. Machine Trap-Vector Base-Address (mtvec) Register
BASE    - MODE
30 Bits - 2 Bits
Mode 0 = Direct, 1 = Vectored
*/
reg [29:0] stvec_base; //30 Bit Address (Lower 2 bits are always 00)
reg [1: 0] stvec_mode; //Vectore Mode Addressing,

reg [31:0] SCAUSE;
reg [31:0] STVAL;
reg [31:0] SEPC;

reg [31:0] csr_data;


wire csr_wr;


always @(posedge clk_i, posedge rst_i) begin
    if(csr_trap_wr_en_i) begin
        //Here need to set the HW controlled Regs
        SEPC <= s_trap_pc_i; 
    end else if(csr_wr_en_i) begin
        case (csr_wr_addr_i)
        `STVEC: begin
            stvec_base <= csr_wr_value_i[31:2];
            stvec_mode <= 2'b0; //Always Vectored for now
        end
         
        endcase
    end
end


//CSR Combinatiol Read
always @(*) begin
    csr_data = 32'b0;

    case(csr_rd_addr_i)
        `STVEC: csr_data = {stvec_base, stvec_mode};
        default: csr_data = 32'b0;
    endcase
end

assign csr_rd_data_o = csr_data;
assign s_tvec_o = {stvec_base,2'b0};
wire [1023:0] csr_in = csr_name(csr_rd_addr_i);
`ifdef CORE_VERBOSITY


function void csr_trace_log(int file);
$fwrite(file,"\nTime: %1t, CSR Name: %0s", $time, csr_in);
endfunction

`endif

endmodule