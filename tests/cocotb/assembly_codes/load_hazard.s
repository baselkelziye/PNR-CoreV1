addi x1 x0 10
lui x31, 0x16
sw x1 0 x31
lw x2 0 x31 #This Instruction is getting flushed
add x3 x2 x2
addi x4 x31 1
lw x5 0 x31
sw x5 4 x31
lw x6 4 x31
