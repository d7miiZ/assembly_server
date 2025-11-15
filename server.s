.intel_syntax noprefix
.globl _start

.section .text

get_method:
    cmp byte ptr [rdi], 0x47 # G
    jne post_check
    mov rax, 1
    ret
 post_check:
    cmp byte ptr [rdi], 0x50 # P
    jne none
    mov rax, 2
    ret
 none:
    mov rax, 0
    ret

get_path:
    mov rax, 0
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



get_payload_len:
    mov rax, 0
    mov r15, 0
    lea rbx, [rip + headers_end]
 count_headers_size_loop:
    cmp rax, rsi # Have we checked all read bytes?
    je payload_not_found

    mov cl, byte ptr[rdi + rax]
    cmp cl, byte ptr[rbx + r15]
    jne reset_counter

    inc rax
    inc r15
    cmp r15, 4 # "\r\n\r\n" size
    je calculate_payload_len
    jmp count_headers_size_loop

   reset_counter:
    # If r15 > 0 then we had a partial match, we need to go back to where the partial match started + 1
    sub rax, r15
    inc rax
    mov r15, 0
    jmp count_headers_size_loop

 calculate_payload_len:
    sub rsi, rax
    mov rax, rsi
    ret

 payload_not_found:
    mov rax, 0
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

 accept_loop:
    mov rdi, r9
    mov rsi, 0
    mov rdx, 0
    mov rax, 43 # accept
    syscall
    mov r10, rax

    mov rax, 57 # fork
    syscall

    cmp rax, 0
    jz child_loop

    mov rdi, r10
    mov rax, 3 # close client socket in parent
    syscall

    jmp accept_loop

 child_loop:
    mov rdi, r9
    mov rax, 3 # close server socket in child
    syscall
    
    mov rdi, r10
    lea rsi, [rip + req_buffer]
    mov rdx, 1024
    mov rax, 0 # read
    syscall    
    mov r14, rax
    
    lea rdi, [rip + req_buffer]
    call get_method
    
    cmp rax, 1
    je get_req
    cmp rax, 2
    je post_req
    jmp done 

 get_req:
    lea rdi, [rip + req_buffer]
    lea rsi, [rip + path_buffer]
    add rdi, 4 # skip "GET "
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

    jmp done
 
 post_req:
    lea rdi, [rip + req_buffer]
    lea rsi, [rip + path_buffer]
    add rdi, 5 # skip "POST "
    call get_path

    lea rdi, [rip + path_buffer]
    mov rsi, 0x41 # O_WRONLY | O_CREAT
    mov rdx, 0x1FF # mode = 0777
    mov rax, 2 # open
    syscall
    mov r13, rax

    lea rdi, [rip + req_buffer]
    mov rsi, r14
    call get_payload_len

    mov rdi, r13
    lea rsi, [rip + req_buffer]
    add rsi, r14
    sub rsi, rax
    mov rdx, rax
    mov rax, 1 # write
    syscall

    mov rdi, r13
    mov rax, 3 # close
    syscall

    mov rdi, r10
    lea rsi, [rip + static_response]
    mov rdx, 19
    mov rax, 1 # write
    syscall

 done:
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
    .long 0             # sin_addr = 0.0.0.0
    .quad 0             # sin_zero[8] = 0
static_response:
    .ascii "HTTP/1.0 200 OK\r\n\r\n"
headers_end:
    .ascii "\r\n\r\n"
