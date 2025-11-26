//Forwarding And Branch (FLUSH) Test
lui x1, 0x10 #0x0 
add x2,x1,x1# 0x4
beq x1 x1 12 #0x8
#We should branch and discard the Following 2 instructions
 lui x3 0xaaaaa#0xc
 lui x5 0xccccc#0x10
 lui x4 0xbbbbb#0x14
 jal x0, 0 #Endless loop
#X3 and X5 shall not be loaded, and LUI x4 0xbbbbb shall be loaded