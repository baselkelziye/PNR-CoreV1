.section .text.trap
    .align 2
    .globl trap_handler

trap_handler:
    # ---------------------------------------------------------
    # 1. Context Save
    # ---------------------------------------------------------
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

    # ---------------------------------------------------------
    # 2. Exception Cause Check
    # ---------------------------------------------------------
    csrr x6, scause       # Read Cause
    
    # Check for Instruction Page Fault (12) -> iTLB Miss
    addi x7, x0, 12
    beq  x6, x7, start_walk
    
    # Check for Load Page Fault (13) -> dTLB Miss
    addi x7, x0, 13
    beq  x6, x7, start_walk

    # Check for Store Page Fault (15) -> dTLB Miss
    addi x7, x0, 15
    beq  x6, x7, start_walk
    
    # If not 12, 13, or 15, just exit (or handle other traps)
    j exit

start_walk:
    # ---------------------------------------------------------
    # 3. The Page Walker (Shared for iTLB and dTLB)
    # ---------------------------------------------------------
    csrr x6, stval        # Faulting Virtual Address (Key)
    csrr x7, satp         # Root Page Table PPN
    slli x7, x7, 12       # Convert PPN to Physical Address
    
    # --- Level 1 Walk ---
    srli x8, x6, 22       # x8 = VPN1
    slli x9, x8, 2        # VPN1 * 4
    add  x9, x7, x9       # PA of Root PTE

    lw   x10, 0(x9)       # x10 = Root PTE
    andi x11, x10, 1      # Valid bit

    bne  x11, x0, root_hit

    # --- Level 1 Allocation ---
    # Formula: L2_PA = Root_Base(x7) + ((VPN1(x8) + 1) * 4096)
    addi x12, x8, 1       # VPN1 + 1
    slli x12, x12, 12     # * 4096 (0x1000)
    add  x13, x7, x12     # x13 = L2_PA
    
    # Create Root PTE (Pointer to L2)
    srli x14, x13, 12     # Get PPN
    slli x14, x14, 10     # Shift to position
    ori  x14, x14, 1      # Set Valid
    sw   x14, 0(x9)       # Update Root Table
    addi x10, x14, 0      # Update x10

root_hit:
    # --- Level 2 Walk ---
    srli x13, x10, 10     # Extract PPN from Root PTE
    slli x13, x13, 12     # Convert to L2 Base Address

    srli x14, x6, 12      # Shift VPN0 to bottom
    andi x14, x14, 0x3FF  # Keep Lower 10 bits only
    
    slli x15, x14, 2      # VPN0 * 4
    add  x15, x13, x15    # PA of L2 Entry
    lw   x16, 0(x15)      # x16 = L2 PTE

    andi x17, x16, 1      # Valid Check
    bne  x17, x0, l2_hit

    # --- Level 2 Allocation (Data Mapping) ---
    # Formula: PA = VA + 0x410000
    lui  x18, 0x410
    add  x19, x6, x18     # x19 = Data PA
    
    # Create Leaf PTE
    srli x20, x19, 12     # Get PPN
    slli x20, x20, 10     # Shift to position
    ori  x20, x20, 0xCF   # Set Valid + R/W/X/A/D Flags
    sw   x20, 0(x15)      # Update L2 Table
    addi x16, x20, 0      # Update x16

l2_hit:
    # ---------------------------------------------------------
    # 4. Final TLB Update (Split by Cause)
    # ---------------------------------------------------------
    # x6  = Virtual Address
    # x16 = PTE Data
    
    # Re-read Cause to decide which TLB to write
    csrr x5, scause
    addi x7, x0, 12
    
    # If Cause == 12 (Instr Fault), go to iTLB Write
    beq  x5, x7, do_itlb_write

    # Else (Cause == 13 or 15), fall through to dTLB Write

do_dtlb_write:
    # dtlb write x6, x16 (Funct3 = 001)
    # Hex: 0x0103100B
    .word 0x0103100B
    j exit

do_itlb_write:
    # itlb write x6, x16 (Funct3 = 000)
    # Hex: 0x0103000B
    .word 0x0103000B
    # Fall through to exit

    # ---------------------------------------------------------
    # 5. Restore Context
    # ---------------------------------------------------------
exit:
    # Restore pointer 0x00010000
    lui x5, 16

    # Restore registers
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