xor x10,x10,x10
xor x11,x11,x11

lui x10, 0xABCD
addi x11,x11,0x555

sw x10,0(x0)

lui x13, 0x6600 #Adress that have same index with x0, different tags
lui x14, 0xDEAD
srli x13,x13,12
sw x14, 0(x13) #Old value should go and be store in DATA RAM

lw x15 0 x0 #This should make us Bring back the data from RAM.
NOP
NOP
NOP
jal x0, 0 #Endless loop