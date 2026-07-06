bits 64
default rel

AF_INET         equ 2
SOCK_STREAM     equ 1
WSA_VERSION     equ 0x0202

segment .data
    route_secret  db "/rahasia", 0

    html_home     db "HTTP/1.1 200 OK", 0xd, 0xa
                  db "Content-Type: text/html", 0xd, 0xa
                  db "Connection: close", 0xd, 0xa
                  db "Content-Length: 53", 0xd, 0xa
                  db 0xd, 0xa
                  db "<html><body><h1>Ini Halaman Utama Assembly!</h1></body></html>"
    len_home      equ $ - html_home

    html_secret   db "HTTP/1.1 200 OK", 0xd, 0xa
                  db "Content-Type: text/html", 0xd, 0xa
                  db "Connection: close", 0xd, 0xa
                  db "Content-Length: 61", 0xd, 0xa
                  db 0xd, 0xa
                  db "<html><body><h1>Ssstt..! endpoint rahasia</h1></body></html>"
    len_secret    equ $ - html_secret

    html_404      db "HTTP/1.1 404 Not Found", 0xd, 0xa
                  db "Content-Type: text/html", 0xd, 0xa
                  db "Connection: close", 0xd, 0xa
                  db "Content-Length: 47", 0xd, 0xa
                  db 0xd, 0xa
                  db "<html><body><h1>Waduh, Gak Ketemu (404)</h1></body></html>"
    len_404       equ $ - html_404

    msg_start     db "Menginisialisasi Web2 Server...", 0xd, 0xa, 0
    msg_listen    db "Server aktif! Buka Firefox ke http://127.0.0.1:8080", 0xd, 0xa, 0

segment .bss
    wsaData       resb 400
    sockaddr_in   resb 16

segment .text
global main
extern printf
extern WSAStartup
extern socket
extern bind
extern listen
extern accept
extern recv
extern send
extern closesocket
extern WSACleanup
extern strstr

main:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 48

    lea     rcx, [msg_start]
    call    printf

    mov     rcx, WSA_VERSION
    lea     rdx, [wsaData]
    call    WSAStartup

    mov     rcx, AF_INET
    mov     rdx, SOCK_STREAM
    xor     r8, r8
    call    socket
    mov     r12, rax

    lea     rax, [sockaddr_in]
    mov     word [rax], AF_INET
    mov     word [rax+2], 0x901F
    mov     dword [rax+4], 0
    mov     qword [rax+8], 0

    mov     rcx, r12
    lea     rdx, [sockaddr_in]
    mov     r8, 16
    call    bind

    mov     rcx, r12
    mov     rdx, 20
    call    listen

    lea     rcx, [msg_listen]
    call    printf

.loop_server:
    mov     rcx, r12
    xor     rdx, rdx
    xor     r8, r8
    call    accept
    mov     r13, rax

    sub     rsp, 1024
    mov     rcx, r13
    mov     rdx, rsp
    mov     r8, 1024
    xor     r9, r9
    call    recv

    mov     rcx, rsp
    lea     rdx, [route_secret]
    call    strstr
    test    rax, rax
    jnz     .send_secret

    mov     rcx, r13
    lea     rdx, [html_home]
    mov     r8, len_home
    xor     r9, r9
    call    send
    jmp     .close_conn

.send_secret:
    mov     rcx, r13
    lea     rdx, [html_secret]
    mov     r8, len_secret
    xor     r9, r9
    call    send

.close_conn:
    add     rsp, 1024

    mov     rcx, r13
    call    closesocket

    jmp     .loop_server

    mov     rcx, r12
    call    closesocket
    call    WSACleanup

    xor     rax, rax
    mov     rsp, rbp
    pop     rbp
    ret
