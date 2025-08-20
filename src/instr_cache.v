`timescale 1ns/1ps

module instr_cache(
//    input rst_i,
    input [31:0] pc_i,
    output [31:0] instr_o
);

localparam MEM_SIZE = 32'h2000000;  // 16 KB
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

  $readmemh("/home/bkelziye/Desktop/PNR-CoreV1/tests/riscof_integration/sim/program_test.hex", instructions);

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
    
//         instructions[0] =  32'h00a00093; // addi x1 x0 10
//         instructions[1] =  32'h00102023; // sw x1 0 x0
//         instructions[2] =  32'h00002103; // lw x2 0 x0
//         instructions[3] =  32'h002101b3; // add x3 x2 x2
//         instructions[4] =  32'h00100213; // addi x4 x0 1
//         instructions[5] =  32'h00002283; // lw x5 0 x0
//         instructions[6] =  32'h00502223; // sw x5 4 x0
//         instructions[7] =  32'h00402303; // lw x6 4 x0


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
    // instructions[0] =  32'h00a00513; // addi x10 x0 10
    // instructions[1] =  32'h00000093; // addi x1 x0 0
    // instructions[2] =  32'h00108093; // addi x1 x1 1 L1
    // instructions[3] =  32'h00000013; // addi x0 x0 0
    // instructions[4] =  32'h00000013; // addi x0 x0 0
    // instructions[5] =  32'h00000013; // addi x0 x0 0
    // instructions[6] =  32'hfe1518e3; // bne x10 x1 -16 <L1>
    // instructions[7] =  32'h00108113; // addi x2 x1 1
    // instructions[8] =  32'h00eef1b7; // lui x3 0xeef
    


/* Peripherals Test
    0:        20000537        lui x10 0x20000
    4:        0a548493        addi x9 x9 165
    8:        00952623        sw x9 12 x10
    c:        0ff00593        addi x11 x0 255
    10:       00b52623       sw x11 12 x10
    14:       05500613       addi x12 x0 85
    18:       00c52623       sw x12 12 x10

    //READ FROM UART

    1c:        00852083        lw x1 8 x10

*/

    //  instructions[0] =  32'h20000537; // lui x10 0x20000
    //  instructions[1] =  32'h0a548493; // addi x9 x9 165
    //  instructions[2] =  32'h00952623; // sw x9 12 x10
    //  instructions[3] =  32'h0f000593; // addi x11 x0 255
    //  instructions[4] =  32'h00b52623; // sw x11 12 x10
    //  instructions[5] =  32'h05500613; // addi x12 x0 85
    //  instructions[6] =  32'h00c52623; // sw x12 12 x10
    //  instructions[7] =  32'h00852083; // lw x1 8 x10

		
// {instructions[3],instructions[2],instructions[1],instructions[0]}         = 32'h7d5c0837;
// {instructions[7],instructions[6],instructions[5],instructions[4]}         = 32'hddb80813;
// {instructions[11],instructions[10],instructions[9],instructions[8]}       = 32'h00785893;
// {instructions[15],instructions[14],instructions[13],instructions[12]}     = 32'h01985793;
// {instructions[19],instructions[18],instructions[17],instructions[16]}     = 32'h00f8e8b3;
// {instructions[23],instructions[22],instructions[21],instructions[20]}     = 32'h0078d913;
// {instructions[27],instructions[26],instructions[25],instructions[24]}     = 32'h0198d793;
// {instructions[31],instructions[30],instructions[29],instructions[28]}     = 32'h00f96933;
// {instructions[35],instructions[34],instructions[33],instructions[32]}     = 32'h00795993;
// {instructions[39],instructions[38],instructions[37],instructions[36]}     = 32'h01995793;
// {instructions[43],instructions[42],instructions[41],instructions[40]}     = 32'h00f9e9b3;
// {instructions[47],instructions[46],instructions[45],instructions[44]}     = 32'h0079da13;
// {instructions[51],instructions[50],instructions[49],instructions[48]}     = 32'h0199d793;
// {instructions[55],instructions[54],instructions[53],instructions[52]}     = 32'h00fa6a33;
// {instructions[59],instructions[58],instructions[57],instructions[56]}     = 32'h007a5a93;
// {instructions[63],instructions[62],instructions[61],instructions[60]}     = 32'h019a5793;
// {instructions[67],instructions[66],instructions[65],instructions[64]}     = 32'h00faeab3;
// {instructions[71],instructions[70],instructions[69],instructions[68]}     = 32'h007adb13;
// {instructions[75],instructions[74],instructions[73],instructions[72]}     = 32'h019ad793;
// {instructions[79],instructions[78],instructions[77],instructions[76]}     = 32'h00fb6b33;
// {instructions[83],instructions[82],instructions[81],instructions[80]}     = 32'h007b5b93;
// {instructions[87],instructions[86],instructions[85],instructions[84]}     = 32'h019b5793;
// {instructions[91],instructions[90],instructions[89],instructions[88]}     = 32'h00fbebb3;
// {instructions[95],instructions[94],instructions[93],instructions[92]}     = 32'h007bdc13;
// {instructions[99],instructions[98],instructions[97],instructions[96]}     = 32'h019bd793;
// {instructions[103],instructions[102],instructions[101],instructions[100]} = 32'h00fc6c33;
// {instructions[107],instructions[106],instructions[105],instructions[104]} = 32'h007c5c93;
// {instructions[111],instructions[110],instructions[109],instructions[108]} = 32'h019c5793;
// {instructions[115],instructions[114],instructions[113],instructions[112]} = 32'h00fcecb3;
// {instructions[119],instructions[118],instructions[117],instructions[116]} = 32'h007cdd13;
// {instructions[123],instructions[122],instructions[121],instructions[120]} = 32'h019cd793;
// {instructions[127],instructions[126],instructions[125],instructions[124]} = 32'h00fd6d33;
// {instructions[131],instructions[130],instructions[129],instructions[128]} = 32'h007d5d93;
// {instructions[135],instructions[134],instructions[133],instructions[132]} = 32'h019d5793;
// {instructions[139],instructions[138],instructions[137],instructions[136]} = 32'h00fdedb3;
// {instructions[143],instructions[142],instructions[141],instructions[140]} = 32'h007dde13;
// {instructions[147],instructions[146],instructions[145],instructions[144]} = 32'h019dd793;
// {instructions[151],instructions[150],instructions[149],instructions[148]} = 32'h00fe6e33;
// {instructions[155],instructions[154],instructions[153],instructions[152]} = 32'h007e5e93;
// {instructions[159],instructions[158],instructions[157],instructions[156]} = 32'h019e5793;
// {instructions[163],instructions[162],instructions[161],instructions[160]} = 32'h00feeeb3;
// {instructions[167],instructions[166],instructions[165],instructions[164]} = 32'h007edf13;
// {instructions[171],instructions[170],instructions[169],instructions[168]} = 32'h019ed793;
// {instructions[175],instructions[174],instructions[173],instructions[172]} = 32'h00ff6f33;
// {instructions[179],instructions[178],instructions[177],instructions[176]} = 32'hfeedc0b7;
// {instructions[183],instructions[182],instructions[181],instructions[180]} = 32'head08093;
// {instructions[187],instructions[186],instructions[185],instructions[184]} = 32'h0070d113;
// {instructions[191],instructions[190],instructions[189],instructions[188]} = 32'h0190d793;
// {instructions[195],instructions[194],instructions[193],instructions[192]} = 32'h00f16133;
// {instructions[199],instructions[198],instructions[197],instructions[196]} = 32'h00715193;
// {instructions[203],instructions[202],instructions[201],instructions[200]} = 32'h01915793;
// {instructions[207],instructions[206],instructions[205],instructions[204]} = 32'h00f1e1b3;
// {instructions[211],instructions[210],instructions[209],instructions[208]} = 32'h0071d213;
// {instructions[215],instructions[214],instructions[213],instructions[212]} = 32'h0191d793;
// {instructions[219],instructions[218],instructions[217],instructions[216]} = 32'h00f26233;
// {instructions[223],instructions[222],instructions[221],instructions[220]} = 32'h00725293;
// {instructions[227],instructions[226],instructions[225],instructions[224]} = 32'h01925793;
// {instructions[231],instructions[230],instructions[229],instructions[228]} = 32'h00f2e2b3;
// {instructions[235],instructions[234],instructions[233],instructions[232]} = 32'h0072d313;
// {instructions[239],instructions[238],instructions[237],instructions[236]} = 32'h0192d793;
// {instructions[243],instructions[242],instructions[241],instructions[240]} = 32'h00f36333;
// {instructions[247],instructions[246],instructions[245],instructions[244]} = 32'h00735393;
// {instructions[251],instructions[250],instructions[249],instructions[248]} = 32'h01935793;
// {instructions[255],instructions[254],instructions[253],instructions[252]} = 32'h00f3e3b3;
// {instructions[259],instructions[258],instructions[257],instructions[256]} = 32'h0073d413;
// {instructions[263],instructions[262],instructions[261],instructions[260]} = 32'h0193d793;
// {instructions[267],instructions[266],instructions[265],instructions[264]} = 32'h00f46433;
// {instructions[271],instructions[270],instructions[269],instructions[268]} = 32'h00745493;
// {instructions[275],instructions[274],instructions[273],instructions[272]} = 32'h01945793;
// {instructions[279],instructions[278],instructions[277],instructions[276]} = 32'h00f4e4b3;
// {instructions[283],instructions[282],instructions[281],instructions[280]} = 32'h0074d513;
// {instructions[287],instructions[286],instructions[285],instructions[284]} = 32'h0194d793;
// {instructions[291],instructions[290],instructions[289],instructions[288]} = 32'h00f56533;
// {instructions[295],instructions[294],instructions[293],instructions[292]} = 32'h00755593;
// {instructions[299],instructions[298],instructions[297],instructions[296]} = 32'h01955793;
// {instructions[303],instructions[302],instructions[301],instructions[300]} = 32'h00f5e5b3;
// {instructions[307],instructions[306],instructions[305],instructions[304]} = 32'h0075d613;
// {instructions[311],instructions[310],instructions[309],instructions[308]} = 32'h0195d793;
// {instructions[315],instructions[314],instructions[313],instructions[312]} = 32'h00f66633;
// {instructions[319],instructions[318],instructions[317],instructions[316]} = 32'h00765693;
// {instructions[323],instructions[322],instructions[321],instructions[320]} = 32'h01965793;
// {instructions[327],instructions[326],instructions[325],instructions[324]} = 32'h00f6e6b3;
// {instructions[331],instructions[330],instructions[329],instructions[328]} = 32'h00000013;
// {instructions[335],instructions[334],instructions[333],instructions[332]} = 32'h00000013;
// {instructions[339],instructions[338],instructions[337],instructions[336]} = 32'h00000013;
// {instructions[343],instructions[342],instructions[341],instructions[340]} = 32'h00000013;
// {instructions[347],instructions[346],instructions[345],instructions[344]} = 32'h00000013;
// {instructions[351],instructions[350],instructions[349],instructions[348]} = 32'h00000013;
// {instructions[355],instructions[354],instructions[353],instructions[352]} = 32'h00006197;
// {instructions[359],instructions[358],instructions[357],instructions[356]} = 32'hfa818193;
// {instructions[363],instructions[362],instructions[361],instructions[360]} = 32'h00000013;
// {instructions[367],instructions[366],instructions[365],instructions[364]} = 32'h00000013;
// {instructions[371],instructions[370],instructions[369],instructions[368]} = 32'h00000013;
// {instructions[375],instructions[374],instructions[373],instructions[372]} = 32'h00000013;
// {instructions[379],instructions[378],instructions[377],instructions[376]} = 32'h00000013;
// {instructions[383],instructions[382],instructions[381],instructions[380]} = 32'h00000013;
// {instructions[387],instructions[386],instructions[385],instructions[384]} = 32'h80000237;
// {instructions[391],instructions[390],instructions[389],instructions[388]} = 32'hfff20213;
// {instructions[395],instructions[394],instructions[393],instructions[392]} = 32'h00100c13;
// {instructions[399],instructions[398],instructions[397],instructions[396]} = 32'h01820c33;
// {instructions[403],instructions[402],instructions[401],instructions[400]} = 32'h0181a023;
// {instructions[407],instructions[406],instructions[405],instructions[404]} = 32'h00020537;
// {instructions[411],instructions[410],instructions[409],instructions[408]} = 32'h00020537;
// {instructions[415],instructions[414],instructions[413],instructions[412]} = 32'h00a50e33;
// {instructions[419],instructions[418],instructions[417],instructions[416]} = 32'h01c1a223;
// {instructions[423],instructions[422],instructions[421],instructions[420]} = 32'hff000ab7;
// {instructions[427],instructions[426],instructions[425],instructions[424]} = 32'hfffa8a93;
// {instructions[431],instructions[430],instructions[429],instructions[428]} = 32'hff000ab7;
// {instructions[435],instructions[434],instructions[433],instructions[432]} = 32'hfffa8a93;
// {instructions[439],instructions[438],instructions[437],instructions[436]} = 32'h015a8ab3;
// {instructions[443],instructions[442],instructions[441],instructions[440]} = 32'h0151a423;
// {instructions[447],instructions[446],instructions[445],instructions[444]} = 32'hffe00b13;
// {instructions[451],instructions[450],instructions[449],instructions[448]} = 32'h00040fb7;
// {instructions[455],instructions[454],instructions[453],instructions[452]} = 32'h01fb0b33;
// {instructions[459],instructions[458],instructions[457],instructions[456]} = 32'h0161a623;
// {instructions[463],instructions[462],instructions[461],instructions[460]} = 32'h55555637;
// {instructions[467],instructions[466],instructions[465],instructions[464]} = 32'h55660613;
// {instructions[471],instructions[470],instructions[469],instructions[468]} = 32'h55555337;
// {instructions[475],instructions[474],instructions[473],instructions[472]} = 32'h55630313;
// {instructions[479],instructions[478],instructions[477],instructions[476]} = 32'h006605b3;
// {instructions[483],instructions[482],instructions[481],instructions[480]} = 32'h00b1a823;
// {instructions[487],instructions[486],instructions[485],instructions[484]} = 32'h00200e93;
// {instructions[491],instructions[490],instructions[489],instructions[488]} = 32'h800006b7;
// {instructions[495],instructions[494],instructions[493],instructions[492]} = 32'h00de8533;
// {instructions[499],instructions[498],instructions[497],instructions[496]} = 32'h00a1aa23;
// {instructions[503],instructions[502],instructions[501],instructions[500]} = 32'hfef00f93;
// {instructions[507],instructions[506],instructions[505],instructions[504]} = 32'h00000293;
// {instructions[511],instructions[510],instructions[509],instructions[508]} = 32'h005f8d33;
// {instructions[515],instructions[514],instructions[513],instructions[512]} = 32'h01a1ac23;
// {instructions[519],instructions[518],instructions[517],instructions[516]} = 32'h66666137;
// {instructions[523],instructions[522],instructions[521],instructions[520]} = 32'h66610113;
// {instructions[527],instructions[526],instructions[525],instructions[524]} = 32'h800000b7;
// {instructions[531],instructions[530],instructions[529],instructions[528]} = 32'hfff08093;
// {instructions[535],instructions[534],instructions[533],instructions[532]} = 32'h001103b3;
// {instructions[539],instructions[538],instructions[537],instructions[536]} = 32'h0071ae23;
// {instructions[543],instructions[542],instructions[541],instructions[540]} = 32'h80000437;
// {instructions[547],instructions[546],instructions[545],instructions[544]} = 32'haaaabcb7;
// {instructions[551],instructions[550],instructions[549],instructions[548]} = 32'haaac8c93;
// {instructions[555],instructions[554],instructions[553],instructions[552]} = 32'h01940733;
// {instructions[559],instructions[558],instructions[557],instructions[556]} = 32'h02e1a023;
// {instructions[563],instructions[562],instructions[561],instructions[560]} = 32'h00000693;
// {instructions[567],instructions[566],instructions[565],instructions[564]} = 32'hfe000437;
// {instructions[571],instructions[570],instructions[569],instructions[568]} = 32'hfff40413;
// {instructions[575],instructions[574],instructions[573],instructions[572]} = 32'h008680b3;
// {instructions[579],instructions[578],instructions[577],instructions[576]} = 32'h0211a223;
// {instructions[583],instructions[582],instructions[581],instructions[580]} = 32'h00100e13;
// {instructions[587],instructions[586],instructions[585],instructions[584]} = 32'h008004b7;
// {instructions[591],instructions[590],instructions[589],instructions[588]} = 32'h009e0033;
// {instructions[595],instructions[594],instructions[593],instructions[592]} = 32'h0201a423;
// {instructions[599],instructions[598],instructions[597],instructions[596]} = 32'h00700713;
// {instructions[603],instructions[602],instructions[601],instructions[600]} = 32'h00200213;
// {instructions[607],instructions[606],instructions[605],instructions[604]} = 32'h00470a33;
// {instructions[611],instructions[610],instructions[609],instructions[608]} = 32'h0341a623;


		
    
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