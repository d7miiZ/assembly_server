.intel_syntax noprefix
.globl _start

.section .text

get_path:
    mov rax, 0
    add rdi, 4 # Skip "GET "
   
    path_loop:
     mov cl, byte ptr [rdi + rax]
     cmp cl, 0x20 # Is space
     je path_exit
     mov byte ptr [rsi + rax], cl
     inc rax
     jmp path_loop
     
    path_exit:
     mov byte ptr [rsi + rax], 0
     ret

_start:
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    mov rax, 41 # socket
    syscall
    mov r9, rax 

    mov rdi, r9
    lea rsi, [rip + sockaddr_in]
    mov rdx, 16
    mov rax, 49 # bind
    syscall 
    
    mov rdi, r9
    mov rsi, 0
    mov rax, 50 # listen
    syscall

    mov rdi, r9
    mov rsi, 0
    mov rdx, 0
    mov rax, 43 # accept
    syscall
    mov r10, rax

    mov rdi, r10
    lea rsi, [rip + req_buffer]
    mov rdx, 1024
    mov rax, 0 # read
    syscall    

    lea rdi, [rip + req_buffer]
    lea rsi, [rip + path_buffer]
    call get_path

    lea rdi, [rip + path_buffer]
    mov rsi, 0
    mov rdx, 0
    mov rax, 2 # open
    syscall
    mov rbx, rax

    mov rdi, rbx
    lea rsi, [rip + res_buffer]
    mov rdx, 1024
    mov rax, 0 # read
    syscall
    mov r12, rax

    mov rdi, rbx
    mov rax, 3 # close
    syscall

    mov rdi, r10
    lea rsi, [rip + static_response]
    mov rdx, 19
    mov rax, 1 # write
    syscall   
 
    mov rdi, r10
    lea rsi, [rip + res_buffer]
    mov rdx, r12
    mov rax, 1 # write
    syscall

    mov rdi, r10
    mov rax, 3 # close
    syscall

    mov rdi, 0
    mov rax, 60 # exit
    syscall

.section .bss
    .align 8
req_buffer:
    .skip 1024
res_buffer:
    .skip 1024
path_buffer:
    .skip 1024

.section .data
sockaddr_in:
    .word 2             # sin_family = AF_INET
    .word 0x5000        # sin_port = htons(80) → 0x0050 → stored as 0x5000  
    .long 0             # sin_addr = 127.0.0.1
    .quad 0             # sin_zero[8] = 0
static_response:
    .ascii "HTTP/1.0 200 OK\r\n\r\n"
