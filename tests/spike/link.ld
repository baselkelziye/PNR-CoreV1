OUTPUT_ARCH(riscv)
ENTRY(_start)

SECTIONS
{
    /* Set Start Address to 0x00000000 */
    . = 0x00000000;

    /* Unified .text section */
    .text : {
        KEEP(*(.text.start))   /* Ensure entry point is always first */
        *(.text)               /* Standard .text sections */
        *(.text.*)             /* All other .text sub-sections */
    }

    /* Standard data sections (placed immediately after code) */
    .rodata : { *(.rodata*) }
    .data   : { *(.data*) }
    .bss    : { *(.bss*) }
}