//Forwarding And Branch (FLUSH) Test
lui x1, 0x10
add x2,x1,x1
beq x1 x1 12
#We should branch and discard the Following 2 instructions
 lui x3 0xaaaaa
 lui x5 0xccccc
 lui x4 0xbbbbb
#X3 and X5 shall not be loaded, and LUI x4 0xbbbbb shall be loaded