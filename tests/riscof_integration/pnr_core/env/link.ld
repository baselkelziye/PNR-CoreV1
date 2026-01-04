SECTIONS
{
    . = 0x00000000;
    .text : { 
        *(.text.init) 
        *(.text) 
        *(.rodata*) 
    }

    /* Move the data section start point further out to avoid overlap */
    /* 0x40000 gives you ~256KB of space for code */
    . = ALIGN(0x1000); 
    . = MAX(., 0x00040000); 

    .data : { 
        *(.data) 
        *(.bss) 
    }

    . = ALIGN(0x1000);
    .signature : { *(.signature) }
}