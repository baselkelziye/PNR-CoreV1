import numpy as np
import os

def generate_matrices(size=128):
    """
    Generate two matrices A and B with specified constraints.
    
    Args:
        size (int): Size of the square matrices (default: 128)
    
    Returns:
        tuple: (matrix_a, matrix_b) as numpy arrays
    """
    # Matrix A: numbers from 1-3
    matrix_a = np.random.randint(1, 4, size=(size, size), dtype=np.uint8)
    
    # Matrix B: numbers 0 and 1
    matrix_b = np.random.randint(0, 2, size=(size, size), dtype=np.uint8)
    
    return matrix_a, matrix_b

def multiply_matrices(matrix_a, matrix_b):
    """
    Multiply two matrices and ensure result fits in 1 byte (0-255).
    
    Args:
        matrix_a, matrix_b: Input matrices as numpy arrays
    
    Returns:
        numpy array: Result matrix with values 0-255
    """
    result = np.matmul(matrix_a.astype(np.uint32), matrix_b.astype(np.uint32))
    
    # Ensure values fit in 1 byte (0-255)
    # For 128x128 matrices with A in 1-3 and B in 0-1, max value is 128*3 = 384
    # So we need to clamp to 255
    result = np.clip(result, 0, 255).astype(np.uint8)
    
    return result

def dump_matrix_to_file(matrix, filename):
    """
    Dump matrix to file with specified format.
    
    Args:
        matrix: numpy array to dump
        filename (str): Output filename
    """
    with open(filename, 'w') as f:
        for row in matrix:
            # Format each number as 2-digit string and join with spaces
            row_str = ' '.join(f"{num:02d}" for num in row)
            f.write(row_str + '\n')

def load_matrix_from_file(filename, size=128):
    """
    Load matrix from file with specified format.
    
    Args:
        filename (str): Input filename
        size (int): Size of the square matrix
    
    Returns:
        numpy array: Loaded matrix
    """
    matrix = np.zeros((size, size), dtype=np.uint8)
    
    with open(filename, 'r') as f:
        for i, line in enumerate(f):
            if i >= size:
                break
            numbers = line.strip().split()
            for j, num_str in enumerate(numbers):
                if j >= size:
                    break
                matrix[i, j] = int(num_str)
    
    return matrix

def generate_and_dump_matrices(size=128):
    """
    Main function to generate matrices, multiply them, and dump to files.
    
    Args:
        size (int): Size of the square matrices
    """
    print(f"Generating {size}x{size} matrices...")
    
    # Generate matrices
    matrix_a, matrix_b = generate_matrices(size)
    
    # Multiply matrices
    matrix_c = multiply_matrices(matrix_a, matrix_b)
    
    # Dump to files
    dump_matrix_to_file(matrix_a, 'large_a.txt')
    dump_matrix_to_file(matrix_b, 'large_b.txt')
    dump_matrix_to_file(matrix_c, 'large_c.txt')
    
    print(f"Matrices dumped to files:")
    print(f"  Matrix A (1-3): large_a.txt")
    print(f"  Matrix B (0-1): large_b.txt")
    print(f"  Result C (0-255): large_c.txt")
    
    # Print some statistics
    print(f"\nMatrix A statistics:")
    print(f"  Range: {matrix_a.min()} - {matrix_a.max()}")
    print(f"  Mean: {matrix_a.mean():.2f}")
    
    print(f"\nMatrix B statistics:")
    print(f"  Range: {matrix_b.min()} - {matrix_b.max()}")
    print(f"  Mean: {matrix_b.mean():.2f}")
    
    print(f"\nResult Matrix C statistics:")
    print(f"  Range: {matrix_c.min()} - {matrix_c.max()}")
    print(f"  Mean: {matrix_c.mean():.2f}")

def verify_multiplication(size=128):
    """
    Verify that the multiplication was performed correctly by loading files and comparing.
    """
    print("\nVerifying multiplication...")
    
    # Load matrices from files
    matrix_a = load_matrix_from_file('large_a.txt', size)
    matrix_b = load_matrix_from_file('large_b.txt', size)
    matrix_c_file = load_matrix_from_file('large_c.txt', size)
    
    # Recompute multiplication
    matrix_c_calculated = multiply_matrices(matrix_a, matrix_b)
    
    # Compare
    if np.array_equal(matrix_c_file, matrix_c_calculated):
        print("✓ Multiplication verified successfully!")
    else:
        print("✗ Multiplication verification failed!")
        print(f"  Mismatches: {np.sum(matrix_c_file != matrix_c_calculated)}")

if __name__ == "__main__":
    # You can change the size here
    MATRIX_SIZE = 128
    
    # Generate and dump matrices
    generate_and_dump_matrices(MATRIX_SIZE)
    
    # Verify the result
    verify_multiplication(MATRIX_SIZE)