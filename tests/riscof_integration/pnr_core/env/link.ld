OUTPUT_ARCH("riscv")
ENTRY(rvtest_entry_point)

SECTIONS
{
    /* 1. Start the code sections at 0x4000 (Instruction Memory) */
    . = 0x4000; 

    /* Define the executable sections first (text, rodata, etc.) */
    .text.init : { *(.text.init) }
    .text : { *(.text) }
    .rodata : { *(.rodata) }

    /* 2. Now, the location counter '.' is automatically set to 
       the address *after* the executable code and read-only data.
       We align the next section (data) to a 4-byte boundary. */
    . = ALIGN(4);
    
    /* 3. Define the data sections to start *after* the code. 
       This prevents the overlap. */
    .data : { *(.data) }
    .data.string : { *(.data.string) }
    .bss : { *(.bss) }

    /* 4. Place the signature section (aligned to 4KB) */
    . = ALIGN(0x1000);
    .signature : { *(.signature) }

    _end = .;
}