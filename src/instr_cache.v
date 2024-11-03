`timescale 1ns/1ps

module instr_cache(
//    input rst_i,
    input [31:0] pc_i,
    output [31:0] instr_o
);

reg [31:0] instructions[0:8191];


assign instr_o = instructions[pc_i[31:2]];

initial begin

//Forwarding And Branch (FLUSH) Test
    // instructions[0] =  32'h000100b7; // lui x1, 0x10
    // instructions[1] =  32'h00108133; // add x2,x1,x1
    // instructions[2] =  32'h00108663; // beq x1 x1 12
//    We should branch and discard the Following 2 instructions
    // instructions[3] =  32'haaaaa1b7; // lui x3 0xaaaaa
    // instructions[4] =  32'hccccc2b7; // lui x5 0xccccc
    // instructions[5] =  32'hbbbbb237; // lui x4 0xbbbbb
//    X3 and X5 shall not be loaded, and LUI x4 0xbbbbb shall be loaded


//Load Hazard Stall Test

/* 
    0:        00a00093        addi x1 x0 10
    4:        00102023        sw x1 0 x0
    8:        00002103        lw x2 0 x0
    c:        002101b3        add x3 x2 x2
    10:       00100213        addi x4 x0 1
    14:       00002283        lw x5 0 x0
    18:       00502223        sw x5 4 x0
    1c:       00402303        lw x6 4 x0
*/
    
        //  instructions[0] =  32'h00a00093; // addi x1 x0 10
        //  instructions[1] =  32'h00102023; // sw x1 0 x0
        //  instructions[2] =  32'h00002103; // lw x2 0 x0
        //  instructions[3] =  32'h002101b3; // add x3 x2 x2
        //  instructions[4] =  32'h00100213; // addi x4 x0 1
        //  instructions[5] =  32'h00002283; // lw x5 0 x0
        //  instructions[6] =  32'h00502223; // sw x5 4 x0
        //  instructions[7] =  32'h00402303; // lw x6 4 x0


/*

Forwarding From Each Stage Test

    0:        00c00093        addi x1 x0 12
    4:        00e00193        addi x3 x0 14
    8:        00a00293        addi x5 x0 10
    c:        55555337        lui x6 0x55555
    10:       40118133        sub x2 x3 x1
    14:       00517633        and x12 x2 x5
    18:       002366b3        or x13 x6 x2
    1c:       00210733        add x14 x2 x2
    20:       002007b3        add x15 x0 x2

*/

    // instructions[0] =  32'h00c00093; // addi x1 x0 12
    // instructions[1] =  32'h00e00193; // addi x3 x0 14
    // instructions[2] =  32'h00a00293; // addi x5 x0 10
    // instructions[3] =  32'h55555337; // lui x6 0x55555
    // instructions[4] =  32'h40118133; // sub x2 x3 x1
    // instructions[5] =  32'h00517633; // and x12 x2 x5
    // instructions[6] =  32'h002366b3; // or x13 x6 x2
    // instructions[7] =  32'h00210733; // add x14 x2 x2
    // instructions[8] =  32'h002007b3; // add x15 x0 x2



/*
    BNE Branch Prediction Test
        0:        00a00513        addi x10 x0 10
    4:        00000093        addi x1 x0 0

00000008 <L1>:
    8:         00108093        addi x1 x1 1
    c:         00000013        addi x0 x0 0
    10:        00000013       addi x0 x0 0
    14:        00000013       addi x0 x0 0
    18:        fe1518e3       bne x10 x1 -16 <L1>
    1c:        00108113       addi x2 x1 1
    20:        00eef1b7       lui x3 0xeef


    */
    instructions[0] =  32'h00a00513; // addi x10 x0 10
    instructions[1] =  32'h00000093; // addi x1 x0 0
    instructions[2] =  32'h00108093; // addi x1 x1 1 L1
    instructions[3] =  32'h00000013; // addi x0 x0 0
    instructions[4] =  32'h00000013; // addi x0 x0 0
    instructions[5] =  32'h00000013; // addi x0 x0 0
    instructions[6] =  32'hfe1518e3; // bne x10 x1 -16 <L1>
    instructions[7] =  32'h00108113; // addi x2 x1 1
    instructions[8] =  32'h00eef1b7; // lui x3 0xeef
    
    
//Bubble Sort Test
        // instructions[0] =  32'h00000093;
        // instructions[1] =  32'h10000113;
        // instructions[2] =  32'h00a00193;
        // instructions[3] =  32'h00900213;
        // instructions[4] =  32'h00200313;
        // instructions[5] =  32'h00610023;
        // instructions[6] =  32'h00100313;
        // instructions[7] =  32'h006100a3;
        // instructions[8] =  32'h00300313;
        // instructions[9] =  32'h00610123;
        // instructions[10] =  32'h00500313;
        // instructions[11] =  32'h006101a3;
        // instructions[12] =  32'h00400313;
        // instructions[13] =  32'h00610223;
        // instructions[14] =  32'h00700313;
        // instructions[15] =  32'h006102a3;
        // instructions[16] =  32'h00600313;
        // instructions[17] =  32'h00610323;
        // instructions[18] =  32'h00b00313;
        // instructions[19] =  32'h006103a3;
        // instructions[20] =  32'h00900313;
        // instructions[21] =  32'h00610423;
        // instructions[22] =  32'h00800313;
        // instructions[23] =  32'h006104a3;
        // instructions[24] =  32'h04328463;
        // instructions[25] =  32'h00000093;
        // instructions[26] =  32'h02408c63;
        // instructions[27] =  32'h002083b3;
        // instructions[28] =  32'h00038403;
        // instructions[29] =  32'h00138713;
        // instructions[30] =  32'h00070483;
        // instructions[31] =  32'h00945863;
        // instructions[32] =  32'h00838023;
        // instructions[33] =  32'h00970023;
        // instructions[34] =  32'h00000863;
        // instructions[35] =  32'h00900533;
        // instructions[36] =  32'h00870023;
        // instructions[37] =  32'h00a38023;
        // instructions[38] =  32'h00108093;
        // instructions[39] =  32'hfc0006e3;
        // instructions[40] =  32'h00128293;
        // instructions[41] =  32'hfa000ee3;
//Starting From cache address 0x100 (256 Dec), array shall be sorted
end

endmodule