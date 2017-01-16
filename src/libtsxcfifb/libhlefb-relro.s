section .text

global __tsx_cfi_fb_hle_ret
global __tsx_cfi_fb_hle_call_rax
global __tsx_cfi_fb_hle_call_rbx
global __tsx_cfi_fb_hle_call_rcx
global __tsx_cfi_fb_hle_call_rdx
global __tsx_cfi_fb_hle_call_rbp
global __tsx_cfi_fb_hle_call_rsp
global __tsx_cfi_fb_hle_call_rdi
global __tsx_cfi_fb_hle_call_rsi
global __tsx_cfi_fb_hle_call_r8
global __tsx_cfi_fb_hle_call_r9
global __tsx_cfi_fb_hle_call_r12
global __tsx_cfi_fb_hle_call_r13
global __tsx_cfi_fb_hle_call_r14
global __tsx_cfi_fb_hle_call_r15
global __tsx_cfi_fb_hle_jmp_rax
global __tsx_cfi_fb_hle_jmp_rbx
global __tsx_cfi_fb_hle_jmp_rcx
global __tsx_cfi_fb_hle_jmp_rdx
global __tsx_cfi_fb_hle_jmp_rbp
global __tsx_cfi_fb_hle_jmp_rsp
global __tsx_cfi_fb_hle_jmp_rdi
global __tsx_cfi_fb_hle_jmp_rsi
global __tsx_cfi_fb_hle_jmp_r8
global __tsx_cfi_fb_hle_jmp_r9
global __tsx_cfi_fb_hle_jmp_r12
global __tsx_cfi_fb_hle_jmp_r13
global __tsx_cfi_fb_hle_jmp_r14
global __tsx_cfi_fb_hle_jmp_r15
global __tsx_cfi_fb_hle_got
global __tsx_cfi_fb_hle_jmp_got
global __tsx_cfi_violation
	

__tsx_cfi_fb_hle_ret:
    shl    r11, 0x20
    mov    r10, 0x00000000ff246c81
    add    r11, r10
	mov    r10,[rsp]
	mov    r10,[r10+2]
	or    r10, 0x0f000000 ; fix for setjmp
    cmp    r10, r11
    jne    __tsx_cfi_violation
    ret    

__tsx_cfi_fb_hle_call_rax:
    push r10
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[rax+2]
    cmp    r11, r10
    mov    r10, rax
    jne    __tsx_cfi_fb_call_reg_internal
    jmp rax

__tsx_cfi_fb_hle_call_rbx:
    push r10
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[rbx+2]
    cmp    r11, r10
    mov    r10, rbx
    jne    __tsx_cfi_fb_call_reg_internal
    jmp rbx

__tsx_cfi_fb_hle_call_rcx:
    push r10
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[rcx+2]
    cmp    r11, r10
    mov    r10, rcx
    jne    __tsx_cfi_fb_call_reg_internal
    jmp rcx

__tsx_cfi_fb_hle_call_rdx:
    push r10
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[rdx+2]
    cmp    r11, r10
    mov    r10, rdx
    jne    __tsx_cfi_fb_call_reg_internal
    jmp rdx

__tsx_cfi_fb_hle_call_rsi:
    push r10
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[rsi+2]
    cmp    r11, r10
    mov    r10, rsi
    jne    __tsx_cfi_fb_call_reg_internal
    jmp rsi

__tsx_cfi_fb_hle_call_rdi:
    push r10
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[rdi+2]
    cmp    r11, r10
    mov    r10, rdi
    jne    __tsx_cfi_fb_call_reg_internal
    jmp rdi
	
__tsx_cfi_fb_hle_call_r8:
    push r10
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[r8+2]
    cmp    r11, r10
    mov    r10, r8
    jne    __tsx_cfi_fb_call_reg_internal
    jmp r8

__tsx_cfi_fb_hle_call_r9:
    push r10
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[r9+2]
    cmp    r11, r10
    mov    r10, r9
    jne    __tsx_cfi_fb_call_reg_internal
    jmp r9

__tsx_cfi_fb_hle_call_r12:
    push r10
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[r12+2]
    cmp    r11, r10
    mov    r10, r12
    jne    __tsx_cfi_fb_call_reg_internal
    jmp r12

__tsx_cfi_fb_hle_call_r13:
    push r10
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[r13+2]
    cmp    r11, r10
    mov    r10, r13
    jne    __tsx_cfi_fb_call_reg_internal
    jmp r13

__tsx_cfi_fb_hle_call_r14:
    push r10
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[r14+2]
    cmp    r11, r10
    mov    r10, r14
    jne    __tsx_cfi_fb_call_reg_internal
    jmp r14

__tsx_cfi_fb_hle_call_r15:
    push r10
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[r15+2]
    cmp    r11, r10
    mov    r10, r15
    jne    __tsx_cfi_fb_call_reg_internal
    jmp r15

__tsx_cfi_fb_hle_call_rbp:
    push r10
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[rbp+2]
    cmp    r11, r10
    jne    __tsx_cfi_violation
    jmp rbp

__tsx_cfi_fb_hle_call_rsp:
    push r10
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[rsp+8+2]
    cmp    r11, r10
    jne    __tsx_cfi_violation
    jmp rsp

;;jmps
	
__tsx_cfi_fb_hle_jmp_rax:
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[rax+2]
    cmp    r11, r10
    jne    __tsx_cfi_violation
    jmp rax

__tsx_cfi_fb_hle_jmp_rbx:
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[rbx+2]
    cmp    r11, r10
    jne    __tsx_cfi_violation
    jmp rbx

__tsx_cfi_fb_hle_jmp_rcx:
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[rcx+2]
    cmp    r11, r10
    jne    __tsx_cfi_violation
    jmp rcx

__tsx_cfi_fb_hle_jmp_rdx:
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[rdx+2]
    cmp    r11, r10
    jne    __tsx_cfi_violation
    jmp rdx

__tsx_cfi_fb_hle_jmp_rsi:
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[rsi+2]
    cmp    r11, r10
    jne    __tsx_cfi_violation
    jmp rsi

__tsx_cfi_fb_hle_jmp_rdi:
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[rdi+2]
    cmp    r11, r10
    jne    __tsx_cfi_violation
    jmp rdi

__tsx_cfi_fb_hle_jmp_rbp:
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[rbp+2]
    cmp    r11, r10
    jne    __tsx_cfi_violation
    jmp rbp
	
__tsx_cfi_fb_hle_jmp_r8:
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[r8+2]
    cmp    r11, r10
    jne    __tsx_cfi_violation
    jmp r8

__tsx_cfi_fb_hle_jmp_r9:
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[r9+2]
    cmp    r11, r10
    jne    __tsx_cfi_violation
    jmp r9

__tsx_cfi_fb_hle_jmp_r12:
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[r12+2]
    cmp    r11, r10
    jne    __tsx_cfi_violation
    jmp r12


__tsx_cfi_fb_hle_jmp_r13:
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[r13+2]
    cmp    r11, r10
    jne    __tsx_cfi_violation
    jmp r13

__tsx_cfi_fb_hle_jmp_r14:
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[r14+2]
    cmp    r11, r10
    jne    __tsx_cfi_violation
    jmp r14

__tsx_cfi_fb_hle_jmp_r15:
    shl    r11, 0x20
    mov    r10, 0x00000000f8246c81
    add    r11, r10
    mov    r10,[r15+2]
    cmp    r11, r10
    jne    __tsx_cfi_violation
    jmp r15

__tsx_cfi_fb_call_reg_internal:
    push rbx
    push rax
    mov    rax, r10
    mov    rbx, rax
    add    rbx, 6
    mov    eax,[rax+2]
    add    rax, rbx 
    mov    rax,[rax]
	mov    rax,[rax-8]
    cmp    rax, r11
    jne    __tsx_cfi_violation
    pop    rax
    pop    rbx
    jmp  r10


__tsx_cfi_violation:
    int3  
