# Matrix base addresses
lui x10, 16          # MatrixA base address (0x00000)
lui x11, 18          # MatrixB base address (0x20000)  
lui x12, 20          # MatrixC base address (0x40000)

# Configuration registers
addi x5,  x0, 3   # size = N (can be 3, 5, 128, etc.)
addi x13, x0, 1     # element size in bytes (for future expansion)
add  x14, x0, x5    # row stride = size (for NxN matrices)

add  x27, x0, x11   # B pointer
add  x6,  x0, x0    # i = 0

loop1:  # Outer loop (rows of A)
    add  x7,  x0, x0      # j = 0
loop2:  # Middle loop (columns of B)
    add  x28, x0, x0      # k = 0
    add  x29, x0, x0      # sum = 0
loop3:  # Inner loop (dot product)
    lb   x30, 0(x10)      # Load A[i][k]
    lb   x31, 0(x27)      # Load B[k][j]
    mul  x30, x30, x31    # Multiply
    add  x29, x29, x30    # Accumulate sum
    
    addi x10, x10, 1      # Move A pointer by element size
    add  x27, x27, x14    # Move B pointer down one row (next k) = +row_stride
    addi x28, x28, 1      # k++
    blt  x28, x5, loop3   # while (k < size)

    sb   x29, 0(x12)      # Store result to C[i][j]
    addi x12, x12, 1      # Next C element
    
    # Reset A row pointer: go back k elements
    sub  x10, x10, x5     # x10 = x10 - size (reset to start of row)
    
    # Move B base to next column
    addi x11, x11, 1      # B base column + 1
    add  x27, x0, x11     # Reset B pointer to new column
    
    addi x7, x7, 1        # j++
    blt  x7, x5, loop2    # while (j < size)

    # Move A to next row: advance by row stride
    add  x10, x10, x14    # x10 = x10 + row_stride
    
    # Reset B base to first column: go back j columns
    sub  x11, x11, x5     # x11 = x11 - size
    add  x27, x0, x11     # Reset B pointer
    
    addi x6, x6, 1        # i++
    blt  x6, x5, loop1    # while (i < size)

end:
    j end