BITS 64

GLOBAL kernel_entry
EXTERN main

section .text
kernel_entry:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    mov rsp, 0x90000
    and rsp, ~0xF
    
    call main

.hang:
    hlt
    jmp .hang