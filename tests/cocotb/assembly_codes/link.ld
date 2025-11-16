OUTPUT_ARCH(riscv)
ENTRY(_start)

SECTIONS
{
    /* Main program goes here */
    . = 0x00000000;
    .text : {
        KEEP(*(.text.start))
        *(.text)              /* only sections named exactly .text */
    }

    /* Trap handler placed at exact address */
    . = 0x00002000;
    .text.trap : {
        KEEP(*(.text.trap))
    }

    /* Catch other .text.* sections (if any) */
    .text.other : {
        *(.text.*)
    }

    /* Other sections */
    .rodata : { *(.rodata*) }
    .data : { *(.data*) }
    .bss  : { *(.bss*) }
}