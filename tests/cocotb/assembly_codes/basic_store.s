lui x10, 0xABCD
addi x10, x10, 0x555
lui x11, 0xDDCC
addi x11,x11, 0x111
sw x10, 0(x0)
sw x11, 4(x0)
xor x15, x15, x15
addi x15, x15, 0x200

sw x0, 0(x15)
