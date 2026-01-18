BITS 16
ORG 0x7C00

STAGE2_LOAD_OFF equ 0x7E00
STAGE2_SECTORS  equ 8

start:
    mov [boot_drive], dl
    
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov ah, 0x02
    mov al, STAGE2_SECTORS
    mov ch, 0x00
    mov cl, 0x02
    mov dh, 0x00
    mov dl, [boot_drive]
    mov bx, STAGE2_LOAD_OFF
    
    int 0x13
    jc disk_error

    jmp STAGE2_LOAD_OFF

disk_error:
    mov si, error_msg
.print_loop:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .print_loop
.done:
    hlt
    jmp $

error_msg: db 'Disk error!', 0
boot_drive: db 0

times 510-($-$$) db 0
dw 0xAA55