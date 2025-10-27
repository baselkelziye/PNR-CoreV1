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

//  {instructions[3],instructions[2],instructions[1],instructions[0]} = 32'h00700713;
//  {instructions[7],instructions[6],instructions[5],instructions[4]} = 32'h00200213;
//  {instructions[11],instructions[10],instructions[9],instructions[8]} = 32'h00470a33;
//  {instructions[15],instructions[14],instructions[13],instructions[12]} = 32'h0341a623;
//   $readmemh("/home/bkelziye/Desktop/PNR-CoreV1/tests/cocotb/machine_codes/basel_bubblesort.hex", instructions);
//   $readmemh("/home/bkelziye/Desktop/PNR-CoreV1/tests/cocotb/machine_codes/mul_test.hex", instructions);
    $readmemh("artifacts/program_test.hex", instructions);

end

endmodule