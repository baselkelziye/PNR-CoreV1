# Initialize x2 to 0
    ADDI x2, x0, 0      
    
    # Jump to 'subroutine' and save return address in x1
    JAL x1, subroutine  
    
    # This instruction is at the 'return address'
    # If JAL worked, x1 should point here
    ADDI x2, x2, 10     # x2 becomes 11 (1 + 10)
    EBREAK              # End of test

subroutine:
    ADDI x2, x2, 1      # x2 becomes 1
    JALR x0, 0(x1)      # Return to the address stored in x1