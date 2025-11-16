#Registers Are saved in Physical Memory Addresses 0x00010000

    .section .text
    .align 2

1:                      # 1: Trap entry

    # Save original x5 into sscratch
    csrw sscratch, x5

    # Build base address 0x00010000 in x5 (destroys x5, now OK)
    lui  x5, 16           # x5 = 0x00010000

    # Save registers
    sw x0,    0(x5)
    sw x1,    4(x5)
    sw x2,    8(x5)
    sw x3,   12(x5)
    sw x4,   16(x5)
    # sw x5,   20(x5)   
    sw x6,   24(x5)
    sw x7,   28(x5)
    sw x8,   32(x5)
    sw x9,   36(x5)
    sw x10,  40(x5)
    sw x11,  44(x5)
    sw x12,  48(x5)
    sw x13,  52(x5)
    sw x14,  56(x5)
    sw x15,  60(x5)
    sw x16,  64(x5)
    sw x17,  68(x5)
    sw x18,  72(x5)
    sw x19,  76(x5)
    sw x20,  80(x5)
    sw x21,  84(x5)
    sw x22,  88(x5)
    sw x23,  92(x5)
    sw x24,  96(x5)
    sw x25, 100(x5)
    sw x26, 104(x5)
    sw x27, 108(x5)
    sw x28, 112(x5)
    sw x29, 116(x5)
    sw x30, 120(x5)
    sw x31, 124(x5)

2:                      # 2: Trap handler body placeholder
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0

3:                      # 3: Restore registers

    # Rebuild pointer again
    lui x5, 16            # x5 = 0x00010000

    # Restore everything except x5 first
    lw x0,    0(x5)
    lw x1,    4(x5)
    lw x2,    8(x5)
    lw x3,   12(x5)
    lw x4,   16(x5)
    # skip x5 for now (will restore from sscratch)
    lw x6,   24(x5)
    lw x7,   28(x5)
    lw x8,   32(x5)
    lw x9,   36(x5)
    lw x10,  40(x5)
    lw x11,  44(x5)
    lw x12,  48(x5)
    lw x13,  52(x5)
    lw x14,  56(x5)
    lw x15,  60(x5)
    lw x16,  64(x5)
    lw x17,  68(x5)
    lw x18,  72(x5)
    lw x19,  76(x5)
    lw x20,  80(x5)
    lw x21,  84(x5)
    lw x22,  88(x5)
    lw x23,  92(x5)
    lw x24,  96(x5)
    lw x25, 100(x5)
    lw x26, 104(x5)
    lw x27, 108(x5)
    lw x28, 112(x5)
    lw x29, 116(x5)
    lw x30, 120(x5)
    lw x31, 124(x5)

    # Restore x5 from sscratch (original x5)
    csrr x5, sscratch

    mret
