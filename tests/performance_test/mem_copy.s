# Mem_copy
# int a[128], b[128];
# for (i=0; i<128; i++) { a[i] = 5; }
# for (i=0; i<128; i++) { b[i] = a[i]; }

addi x1,x0, 0 #Base Address for a[]
addi x3, x0, 1024 # Base address for b[]

addi x2, x0, 128 #Size for a[], b[] = 128
addi x4, x2, 0 #1 More register for Size of arrays, To be used as iterator
addi x6, x1, 0 #Save Base Address for a[] because in loop we update this

addi x5,x0,5 #Const Value = 5


a_arr_assignment:
    beq x2,x0, a_arr_assignment_exit
    sw x5, 0(x6)
    addi x6, x6,4
    addi x2,x2,-1
    beq x0,x0, a_arr_assignment
    
a_arr_assignment_exit:
    beq x4, x0, b_arr_copy_exit
    lw x7, 0(x1) # x7 = a[i]
    sw x7, 0(x3) # Probably i can insert here a trick, start x3 with addr -4. TODO LATER
    addi x1,x1,4
    addi x3,x3,4
    addi x4,x4,-1
    beq x0,x0, a_arr_assignment_exit
b_arr_copy_exit:
    addi x0,x0,0
    
    
    