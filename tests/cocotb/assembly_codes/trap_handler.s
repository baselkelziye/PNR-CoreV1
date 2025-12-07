    .section .text.trap
    .align 2
    .globl trap_handler

trap_handler:

    # Save original x5 into sscratch
    csrw sscratch, x5

    # Build base pointer 0x00010000
    lui  x5, 16

    # Save registers
    sw x0,    0(x5)
    sw x1,    4(x5)
    sw x2,    8(x5)
    sw x3,   12(x5)
    sw x4,   16(x5)
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

    # Trap body placeholder
    # csrr t1,sepc
    # addi t1,t1,4
    # csrw sepc,t1
    csrr x6, scause #Cause of Exception
    addi x7,x0,12 #Instruction Page Fault (TLB miss in our case)
    
    beq x7, x6, itlb_miss #SCAUSE = instruction page fault

    j exit
    itlb_miss:
        csrr x6, stval #Faulting VA
        csrr x7, satp #Root Page Table Addr
        slli x7,x7, 12 #??
        srli x8,x6, 22 #X8 = VPN1
        slli x9,x8,2 #VPN1 * 4
        add x9,x7,x9 #PA of PTE

        lw x10, 0(x9) #X10 = PTE
        andi x11,x10,1 #Valid bit

        bne x11,x0,root_hit
        #Here the First PTE is invalid, And we need to Allocate it
        #L2_PA = Root_Base(x7) + ((VPN1(x8) + 1) * 4096)
        addi x12,x8,1 #VPN1 + 1
        slli x12,x12,12 # * 0x1000
        add x13,x7,x12 #SATP + OFFSET
        #Creat PTE
        srli x14, x13, 12 #x14 = L2_PPN 
        slli x14, x14, 10
        ori x14, x14, 1 #Valid Bit Append
        sw x14, 0(x9) #Write to PTE
        addi x10, x14, 0

    root_hit:
        srli x13, x10, 10
        slli x13, x13, 12

        srli x14, x6, 12 #Shift VPN0 to bottom
        andi x14, x14, 0x3ff #Keep Lower 10 bits only
        #Address of L2 Entry
        slli x15, x14, 2 # x15 = VPN0 * 4
        add x15, x13, x15 # PA of L2 Entry
        lw x16, 0(x15) #X16 = PTE

        andi x17, x16, 1
        bne x17, x0, l2_hit
        #Here L2 PTE is inValid
        #Translation Scheme = PA = VA + 0x410000
        lui x18, 0x410
        add x19, x6, x18 #X19 = PA Mapping
        #Create LEAF PTE
        srli x20,x19,12 
        slli x20,x20, 10
        ori x20, x20, 0xCF #Valid, Flags, Etc.
        sw x20, 0(x15)
        addi x16, x20, 0
        l2_hit:
        # ---------------------------------------------------------
        # CUSTOM INSTRUCTION: itlb write x6, x16
        # ---------------------------------------------------------
        # Encoding (R-Type Custom-0):
        # opcode = 0001011 (Custom-0)
        # rd     = 00000   (x0 - unused)
        # funct3 = 000
        # rs1    = 00110   (x6 - Virtual Address)
        # rs2    = 10000   (x16 - PTE)
        # funct7 = 0000000
        #
        # Binary: 0000000_10000_00110_000_00000_0001011
        # Hex:    0x0103000B
    
        .word 0x0103000B    # itlb write x6, x16

    # Restore pointer 0x00010000
    exit:
    lui x5, 16

    # Restore registers except x5
    lw x0,    0(x5)
    lw x1,    4(x5)
    lw x2,    8(x5)
    lw x3,   12(x5)
    lw x4,   16(x5)
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

    # Restore real x5
    csrr x5, sscratch

    sret
    