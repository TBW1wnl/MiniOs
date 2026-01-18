BITS 16
ORG 0x7E00

KERNEL_LOAD_OFF equ 0x8000
KERNEL_SECTORS  equ 16

stage2_start:
    mov [boot_drive], dl

    xor ax, ax
    mov es, ax
    mov bx, KERNEL_LOAD_OFF

    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0x00
    mov cl, 0x02 + 8
    mov dh, 0x00
    mov dl, [boot_drive]
    
    int 0x13
    jc error

    call enable_a20

    cli
    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp 0x08:protected_mode_start

error:
    hlt
    jmp $

enable_a20:
    in al, 0x92
    or al, 2
    out 0x92, al
    ret

gdt_start:
    dq 0x0000000000000000  ; Null descriptor
    dq 0x00CF9A000000FFFF  ; Code 32-bit
    dq 0x00CF92000000FFFF  ; Data 32-bit
    dq 0x00AF9A000000FFFF  ; Code 64-bit
    dq 0x00AF92000000FFFF  ; Data 64-bit
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

BITS 32
protected_mode_start:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, 0x90000

    call check_long_mode
    test eax, eax
    jz no_long_mode

    call setup_page_tables
    
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    mov eax, 0x1000
    mov cr3, eax

    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    lgdt [gdt_descriptor]
    jmp 0x18:long_mode_start

no_long_mode:
    hlt
    jmp $

check_long_mode:
    pushfd
    pop eax
    mov ecx, eax
    xor eax, 1 << 21
    push eax
    popfd
    pushfd
    pop eax
    push ecx
    popfd
    xor eax, ecx
    jz .no_cpuid

    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb .no_long_mode

    mov eax, 0x80000001
    cpuid
    test edx, 1 << 29
    jz .no_long_mode

    mov eax, 1
    ret

.no_cpuid:
.no_long_mode:
    xor eax, eax
    ret

setup_page_tables:
    mov edi, 0x1000
    mov ecx, 0x1000
    xor eax, eax
    rep stosd

    mov dword [0x1000], 0x2003
    mov dword [0x2000], 0x3003
    mov dword [0x3000], 0x4003

    mov edi, 0x4000
    mov eax, 0x0003
    mov ecx, 512
.map_page:
    mov [edi], eax
    add eax, 0x1000
    add edi, 8
    loop .map_page

    ret

BITS 64
long_mode_start:
    mov ax, 0x20
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov rsp, 0x90000

    mov rsi, KERNEL_LOAD_OFF
    mov rdi, 0x100000
    mov rcx, KERNEL_SECTORS * 512 / 8
    rep movsq

    call 0x100000

.hang:
    hlt
    jmp .hang

boot_drive: db 0

times 4096-($-$$) db 0