/* linker.ld - Script de linker pour le kernel 64-bit */

ENTRY(kernel_entry)
OUTPUT_FORMAT(binary)

SECTIONS
{
    . = 0x100000;

    .text : ALIGN(4096)
    {
        *(.text*)
    }

    .rodata : ALIGN(4096)
    {
        *(.rodata*)
    }

    .data : ALIGN(4096)
    {
        *(.data*)
    }

    .bss : ALIGN(4096)
    {
        *(COMMON)
        *(.bss*)
    }
}