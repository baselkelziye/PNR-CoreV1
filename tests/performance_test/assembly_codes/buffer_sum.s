# Buffer_sum
# int a[128], sum = 0;
# for (i=0; i<128; i++) { sum += a[i]; }


lui x1, 0x16 # x1 = base address (0x100) THIS IS DONE in cocotb (backdoor access)
addi x10, x0, 128     # x10 = number of words
addi x5, x0, 0        # x5 = sum accumulator

sum_loop:
    beq  x10, x0, exit_sum   # if counter == 0 → exit
    lw   x6, 0(x1)           # load word from memory
    addi x1, x1, 4           # move to next word (word addressing)
    addi x10, x10, -1        # decrement counter
    add  x5, x5, x6          # accumulate
    beq  x0, x0, sum_loop    # unconditional jump

exit_sum:
    nop
    jal x0, 0 #Endless loop