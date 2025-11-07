lui x10, 0x11111
lui x11, 0x22222
lui x12, 0x33333
lui x13, 0x44444
lui x14, 0x99999 # SB Should be Full, A Drain and Write to tag array should occur

sw x10, 0(x0)
sw x11, 32(x0)
sw x12, 64(x0)
sw x13, 128(x0)
sw x14, 256(x0)
lw x15, 128(x0) #Load Data From SB, Bypass test