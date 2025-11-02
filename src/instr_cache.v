`timescale 1ns/1ps

module instr_cache(
//    input rst_i,
    input [31:0] pc_i,
    output [31:0] instr_o
);

localparam MEM_SIZE = 32'h200000;  // 16 KB
localparam IMEM_BASE = 32'h80000000;

reg [7:0] instructions[0:MEM_SIZE-1];


assign instr_o = {
    instructions[pc_i - IMEM_BASE + 3],
    instructions[pc_i - IMEM_BASE + 2],
    instructions[pc_i - IMEM_BASE + 1],
    instructions[pc_i - IMEM_BASE + 0]
};
// assign instr_o = instructions[pc_i];

initial begin

//    $readmemh("/home/bkelziye/Desktop/PNR-CoreV1/tests/cocotb/machine_codes/basel_bubblesort.hex", instructions);
    // $readmemh("artifacts/program_test.hex", instructions);
    // $readmemh("/home/bkelziye/Desktop/PNR-CoreV1/tests/performance_test/machine_codes/matrix_mul.hex", instructions);
    $readmemh("/home/bkelziye/Desktop/PNR-CoreV1/tests/performance_test/machine_codes/matrix_mul_large.hex", instructions);

end

endmodule