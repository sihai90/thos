;=======================================================================
; Copyright Baptiste Wicht 2013.
; Distributed under the Boost Software License, Version 1.0.
; (See accompanying file LICENSE_1_0.txt or copy at
;  http://www.boost.org/LICENSE_1_0.txt)
;=======================================================================

[BITS 16]

jmp rm_start

%include "intel_16.asm"

; Start in real mode
rm_start:
    ; Set stack space (4K) and stack segment
    mov ax, 0x9C0
    add ax, 288
    mov ss, ax
    mov sp, 4096

    ; Set data segment
    mov ax, 0x7C0
    mov ds, ax

    ; Set video mode
    mov ah, 0x01
    mov cx, 0x2607
    int 0x10

    ; 2. Welcome the user to the bootloader

    call new_line_16

    mov si, header_0
    call print_line_16

    mov si, header_1
    call print_line_16

    mov si, header_2
    call print_line_16

    call new_line_16

    mov si, press_key_msg
    call print_line_16

    call new_line_16

    ; Enable A20 gate
    in al, 0x92
    or al, 2
    out 0x92, al

    ; Wait for any key
    call key_wait

    mov si, load_kernel
    call print_line_16

    ; Reset disk drive
    xor ax, ax
    xor ah, ah
    mov dl, 0
    int 0x13

    jc reset_failed

    ; Loading the stage 2 from floppy

    bootdev equ 0x0
    sectors equ 1

    mov ax, 0x90
    mov es, ax
    xor bx, bx

    mov ah, 0x2         ; Read sectors from memory
    mov al, sectors     ; Number of sectors to read
    xor ch, ch          ; Cylinder 0
    mov cl, 2           ; Sector 2
    xor dh, dh          ; Head 0
    mov dl, bootdev     ; Drive
    int 0x13

    jc read_failed

    cmp al, sectors
    jne read_failed

    ; Run the assembly kernel

    jmp dword 0x90:0x0

reset_failed:
    mov si, reset_failed_msg
    call print_line_16

    jmp error_end

read_failed:
    mov si, read_failed_msg
    call print_line_16

error_end:
    mov si, load_failed
    call print_line_16

    jmp $

; Datas

    header_0 db '******************************', 0
    header_1 db 'Welcome to Thor OS Bootloader!', 0
    header_2 db '******************************', 0

    press_key_msg db 'Press any key to load the kernel...', 0
    load_kernel db 'Attempt to load the stage 2...', 0

    reset_failed_msg db 'Reset disk failed', 0
    read_failed_msg db 'Read disk failed', 0
    load_failed db 'Stage 2 loading failed', 0

; Make a real bootsector

    times 510-($-$$) db 0
    dw 0xAA55