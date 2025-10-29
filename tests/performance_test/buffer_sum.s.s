# Mem_copy
# int a[128], b[128];
# for (i=0; i<128; i++) { a[i] = 5; }
# for (i=0; i<128; i++) { b[i] = a[i]; }

addi x1,x0, 256 #Base Address for a[]
addi x3, x0, 512 # Base address for b[]

addi x2, x0, 128 #Size for a[], b[] = 128
addi x4, x2, 0 #1 More register for Size of arrays, To be used as iterator
addi x6, x1, 0 #Save Base Address for a[] because in loop we update this

addi x5,x0,5 #Const Value = 5


a_arr_assignment:
    beq x2,x0, a_arr_assignment_exit
    sw x5, 0(x6)
    addi x6, x6,4
    beq x0,x0, a_arr_assignment
    
    
a_arr_assignment_exit:
    NOP
    
    
    