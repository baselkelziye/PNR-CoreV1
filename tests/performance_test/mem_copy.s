lui x10, 0x11111
lui x11, 0x22222
lui x12, 0x33333
lui x13, 0x44444
lui x14, 0x99999 # SB Should be Full, A Drain and Write to tag array should occur
lui x31, 0x16
sw x10, 0(x31)
sw x11, 32(x31)
sw x12, 64(x31)
sw x13, 128(x31)
sw x14, 256(x31)
lw x15, 128(x31) #Load Data From SB, Bypass test
sw x10, 0(x31)
sw x11, 0(x31)
sw x12, 0(x31)
sw x14, 0(x31)
lw x16, 0(x31) #X16  Should be  0x99999000
addi x17,x31,0x777
sw x16, 32(x31)
sb x17, 32(x31)
lw x18, 32(x31) #lw should be 99999077