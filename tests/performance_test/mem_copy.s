addi x1, x0, 1
addi x3, x0, 3
add  x4, x1, x3
addi x1, x0, 100  # Overwrites the RAT entry for x1
add  x5, x1, x0   # x5 should wait for the NEW x1 (100), not the old one (1)