xor x6,x6,x6
addi x7,x0 0x05
slli x7,x7,12
srli x8,x6,22 #x8 = VPN1
slli x9,x8,2 #VPN1 * 4
add x9,x7,x9 # PA of PTE
lw x10, 0(x9) #X10 = PTE
andi x11,x10,1 #Valid bit
bne x10,x0, root_hit
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
        nop