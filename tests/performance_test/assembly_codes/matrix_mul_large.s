# Matrix base addresses
lui x10, 0          # MatrixA base address
lui x11, 1          # MatrixB base address  
lui x12, 2          # MatrixC base address

# Configuration
addi x5,  x0, 128   # size = N
addi x13, x0, 1     # element size in bytes
add  x14, x0, x5    # row stride = size (bytes per row)

add  x6,  x0, x0    # i = 0

loop1:  # Outer loop (rows of A)
    add  x7,  x0, x0      # j = 0
loop2:  # Middle loop (columns of B)
    add  x28, x0, x0      # k = 0
    add  x29, x0, x0      # sum = 0
    
    # Calculate current element pointers
    add  x15, x10, x0     # A[i][0] - start of current A row
    add  x16, x11, x7     # B[0][j] - start of current B column
    
loop3:  # Inner loop (dot product)
    lb   x30, 0(x15)      # Load A[i][k]
    lb   x31, 0(x16)      # Load B[k][j]
    mul  x30, x30, x31    # Multiply
    add  x29, x29, x30    # Accumulate sum
    
    addi x15, x15, 1      # Move to next element in A row (A[i][k+1])
    add  x16, x16, x14    # Move to next element in B column (B[k+1][j])
    addi x28, x28, 1      # k++
    blt  x28, x5, loop3   # while (k < size)

    sb   x29, 0(x12)      # Store result to C[i][j]
    addi x12, x12, 1      # Next C element
    
    addi x7, x7, 1        # j++
    blt  x7, x5, loop2    # while (j < size)

    # Move to next A row
    add  x10, x10, x14    # A base += row_stride
    
    addi x6, x6, 1        # i++
    blt  x6, x5, loop1    # while (i < size)

end:
    j end