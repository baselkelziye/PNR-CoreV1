# Matrix base addresses
lui x10, 0          # MatrixA base address (0x00000)
lui x11, 1          # MatrixB base address (0x20000)
lui x12, 2          # MatrixC base address (0x40000)

addi x5,  x0, 128   # size = 128
add  x27, x0, x11   # B pointer
add  x6,  x0, x0    # i = 0

loop1:  # Outer loop (rows of A)
    add  x7,  x0, x0      # j = 0
loop2:  # Middle loop (columns of B)
    add  x28, x0, x0      # k = 0
    add  x29, x0, x0      # sum = 0
loop3:  # Inner loop (dot product)
    lb   x30, 0(x10)      # Load A[i][k] (1 byte)
    lb   x31, 0(x27)      # Load B[k][j] (1 byte)
    mul  x30, x30, x31    # Multiply bytes
    add  x29, x29, x30    # Accumulate sum
    # andi x29, x29, 255   # optional mod 256 (if needed to keep within byte range)
    addi x10, x10, 1      # Move A pointer by 1 byte
    addi x27, x27, 128    # Move B pointer down one row (next k), assuming 128 columns
    addi x28, x28, 1      # k++
    blt  x28, x5, loop3   # while (k < size)

    sb   x29, 0(x12)      # Store result byte to C[i][j]
    addi x12, x12, 1      # Next C element (j+1)
    addi x10, x10, -128   # Reset A row pointer
    addi x11, x11, 1      # Move B base pointer to next column
    add  x27, x0, x11     # Reset B pointer
    addi x7, x7, 1        # j++
    blt  x7, x5, loop2    # while (j < size)

    addi x10, x10, 128    # Move A to next row (i+1)
    addi x11, x11, -128   # Reset B base pointer
    add  x27, x0, x11     # Reset B pointer
    addi x6, x6, 1        # i++
    blt  x6, x5, loop1    # while (i < size)

end:
    j end
