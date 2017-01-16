section .text

global __tsx_cfi_fb_rtm_ret
global __tsx_cfi_fb_rtm_call_rax
global __tsx_cfi_fb_rtm_call_rbx
global __tsx_cfi_fb_rtm_call_rcx
global __tsx_cfi_fb_rtm_call_rdx
global __tsx_cfi_fb_rtm_call_rbp
global __tsx_cfi_fb_rtm_call_rsp
global __tsx_cfi_fb_rtm_call_rdi
global __tsx_cfi_fb_rtm_call_rsi
global __tsx_cfi_fb_rtm_call_r8
global __tsx_cfi_fb_rtm_call_r9
global __tsx_cfi_fb_rtm_call_r12
global __tsx_cfi_fb_rtm_call_r13
global __tsx_cfi_fb_rtm_call_r14
global __tsx_cfi_fb_rtm_call_r15
global __tsx_cfi_fb_rtm_jmp_rax
global __tsx_cfi_fb_rtm_jmp_rbx
global __tsx_cfi_fb_rtm_jmp_rcx
global __tsx_cfi_fb_rtm_jmp_rdx
global __tsx_cfi_fb_rtm_jmp_rbp
global __tsx_cfi_fb_rtm_jmp_rsp
global __tsx_cfi_fb_rtm_jmp_rdi
global __tsx_cfi_fb_rtm_jmp_rsi
global __tsx_cfi_fb_rtm_jmp_r8
global __tsx_cfi_fb_rtm_jmp_r9
global __tsx_cfi_fb_rtm_jmp_r12
global __tsx_cfi_fb_rtm_jmp_r13
global __tsx_cfi_fb_rtm_jmp_r14
global __tsx_cfi_fb_rtm_jmp_r15
global __tsx_cfi_fb_rtm_got
global __tsx_cfi_fb_rtm_jmp_got
global __tsx_cfi_violation
	

__tsx_cfi_fb_rtm_ret:
    mov    rax, [rsp]
    mov    rax,[rax]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    jne    __tsx_cfi_violation
    mov    rax,r11
    pop    r10
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_call_rax:
    mov    rax,[r11]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    mov    rax,r11
    push r10
    mov r10, rax
    jne    __tsx_cfi_fb_call_reg_internal 
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_call_rbx:
    mov    rax,[rbx]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    mov    rax,r11
    push r10
    mov r10, rbx
    jne    __tsx_cfi_fb_call_reg_internal 
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_call_rcx:
    mov    rax,[rcx]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    mov    rax,r11
    push r10
    mov r10, rcx
    jne    __tsx_cfi_fb_call_reg_internal 
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_call_rdx:
    mov    rax,[rdx]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    mov    rax,r11
    push r10
    mov r10, rdx
    jne    __tsx_cfi_fb_call_reg_internal 
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_call_rdi:
    mov    rax,[rdi]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    mov    rax,r11
    push r10
    mov r10, rdi
    jne    __tsx_cfi_fb_call_reg_internal 
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_call_rbp:
    mov    rax,[rbp]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    mov    rax,r11
    push r10
    mov r10, rbp
    jne    __tsx_cfi_fb_call_reg_internal 
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_call_rsp:
    mov    rax,[rsp]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    mov    rax,r11
    push r10
    mov r10, rsp
    jne    __tsx_cfi_fb_call_reg_internal 
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_call_rsi:
    mov    rax,rsi
    mov    rax,[rax]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    mov    rax,r11
    push r10
    mov r10, rsi
    jne    __tsx_cfi_fb_call_reg_internal 
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_call_r8:
    mov    rax,[r8]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    mov    rax,r11
    push r10
    mov r10, r8
    jne    __tsx_cfi_fb_call_reg_internal 
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_call_r9:
    mov    rax,[r9]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    mov    rax,r11
    push r10
    mov r10, r9
    jne    __tsx_cfi_fb_call_reg_internal 
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_call_r12:
    mov    rax,[r12]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    mov    rax,r11
    push r10
    mov r10, r12
    jne    __tsx_cfi_fb_call_reg_internal 
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_call_r13:
    mov    rax,[r13]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    mov    rax,r11
    push r10
    mov r10, r13
    jne    __tsx_cfi_fb_call_reg_internal 
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_call_r14:
    mov    rax,[r14]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    mov    rax,r11
    push r10
    mov r10, r14
    jne    __tsx_cfi_fb_call_reg_internal 
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_call_r15:
    mov    rax,[r15]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    mov    rax,r11
    push r10
    mov r10, r15
    jne    __tsx_cfi_fb_call_reg_internal 
	add r10, 3
	jmp r10
;;jmps
__tsx_cfi_fb_rtm_jmp_rax:
    mov    rax,[r11]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    jne    __tsx_cfi_violation
    mov    rax,r11
    mov r10, rax
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_jmp_rbx:
    mov    rax,[rbx]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    jne    __tsx_cfi_violation
    mov    rax,r11
    mov r10, rbx
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_jmp_rcx:
    mov    rax,[rcx]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    jne    __tsx_cfi_violation
    mov    rax,r11
    mov r10, rcx
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_jmp_rdx:
    mov    rax,[rdx]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    jne    __tsx_cfi_violation
    mov    rax,r11
    mov r10, rdx
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_jmp_rdi:
    mov    rax,[rdi]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    jne    __tsx_cfi_violation
    mov    rax,r11
    mov r10, rdi
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_jmp_rbp:
    mov    rax,[rbp]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    jne    __tsx_cfi_violation
    mov    rax,r11
    mov r10, rbp
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_jmp_rsp:
    mov    rax,[rsp]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    jne    __tsx_cfi_violation
    mov    rax,r11
    mov r10, rsp
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_jmp_rsi:
    mov    rax,rsi
    mov    rax,[rax]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    jne    __tsx_cfi_violation
    mov    rax,r11
    mov r10, rsi
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_jmp_r8:
    mov    rax,[r8]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    jne    __tsx_cfi_violation
    mov    rax,r11
    mov r10, r8
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_jmp_r9:
    mov    rax,[r9]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    jne    __tsx_cfi_violation
    mov    rax,r11
    mov r10, r9
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_jmp_r12:
    mov    rax,[r12]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    jne    __tsx_cfi_violation
    mov    rax,r11
    mov r10, r12
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_jmp_r13:
    mov    rax,[r13]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    jne    __tsx_cfi_violation
    mov    rax,r11
    mov r10, r13
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_jmp_r14:
    mov    rax,[r14]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    jne    __tsx_cfi_violation
    mov    rax,r11
    mov r10, r14
	add r10, 3
	jmp r10

__tsx_cfi_fb_rtm_jmp_r15:
    mov    rax,[r15]
    and    eax,0xffffff
    cmp    eax,0xd5010f
    jne    __tsx_cfi_violation
    mov    rax,r11
    mov r10, r15
	add r10, 3
	jmp r10

__tsx_cfi_fb_call_reg_internal:
    push   r11
    push   rbx
    mov    rax, r10
    mov    rbx, rax
    add    rbx, 6
    mov    eax,[rax+2]
    add    rax, rbx 
    mov    rax,[rax]
    cmp    rax, rbx ; check if it is an unresolved got entry
    mov    r11,rax
    je     valid

    mov    rax,[rax]	
    and    eax,0xffffff
    cmp    eax,0xd5010f
    jne    __tsx_cfi_violation
    add  r11,3
    jmp valid






__tsx_cfi_fb_rtm_got:
    push r10
    push   r11
__tsx_cfi_fb_rtm_jmp_got:
    push   rbx
    mov    eax,[r10-4]
    add    rax,r10
    and    eax,0xffffffff
    add    rax,2  
    mov    rbx, rax
    add    rbx, 4
    mov    eax,[rax]
    add    rax, rbx 
    mov    rax,[rax]
    cmp    rax, rbx ; check if it is an unresolved got entry
    mov    r11,rax
    je     valid

    mov    rax,[rax]	
    and    eax,0xffffff
    cmp    eax,0xd5010f
    jne    __tsx_cfi_violation
    add  r11,3
    valid:
    pop    rbx
    pop  rax
    jmp  r11


__tsx_cfi_violation:
    int3  
