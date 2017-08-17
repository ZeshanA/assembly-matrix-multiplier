;
; ***************************************************************
;       INTEL ASSEMBLER MATRIX MULTIPLY (LINUX)
; ***************************************************************
;

segment .text
        global  _start
_start:

main:
          mov  rax, matrixA     ; matrixA.print ()
          push rax              ; push address of matrixA) onto stack
          call matrix_print     ; print matrixA
          add  rsp, 8

          mov  rax, matrixB     ; matrixB.print ()
          push rax
          call matrix_print
          add  rsp, 8

          mov  rax, matrixB     ; matrixC.mult (matrixA, matrixB)
          push rax
          mov  rax, matrixA
          push rax
          mov  rax, matrixC
          push rax
          call matrix_mult
          add  rsp, 24          ; pop parameters & object reference

          mov  rax, matrixC     ; matrixC.print ()
          push rax
          call matrix_print
          add  rsp, 8

          call os_return                ; return to operating system

; ---------------------------------------------------------------------

matrix_print:                   ; void matrix_print ()
         push rbp               ; setup base pointer
         mov  rbp, rsp

         push rax               ; rax contains the memory address of matrix{A/B/C}, push to preserve it
         push rbx               ; we will use rbx to store number of ROWS
         push rcx               ; we will use rcx to store number of COLS
         push rdx               ; we will use rdx for the row iterator
         push r15               ; we will use r15 for the column iterator
         push r14               ; register for temporarily storing calculations
         push r13               ; same as r14
         
         mov rax, [rbp + 16]    ; address for start of matrix object

         mov rbx, [rax]         ; rbx = ROWS

         mov rcx, [rax + 8]     ; rcx = COLS

         call output_newline    ; print an empty line
         mov rdx, 0             ; rdx = 0 (row iterator, outer loop)

         printRowLoop:
            cmp rdx, rbx        ; compare rdx (row iterator) with rbx (number of rows)
            jge printRowLoopEnd ; if rbx >= rdx, jump outside outer loop

            mov r15, 0          ; r15 = 0 (column iterator, inner loop)

            printColumnLoop:
                cmp r15, rcx              ; compare r15 (column iterator) with rcx (number of columns)
                jge printColumnLoopEnd    ; if rcx >= r15, jump outside inner loop
                call output_tab           ; output a tab character

                mov  r14, 8               ; r14 = 8
                imul r14, rcx             ; r14 = 8 * COLS
                imul r14, rdx             ; r14 = 8 * COLS * ROWINDEX
                add  r14, 16              ; r14 = 16 + (8 * COLS * ROWINDEX)
                add  r14, rax             ; r14 = rax + 16 + (8 * COLS * ROWINDEX)

                mov  r13, 8               ; r13 = 8
                imul r13, r15             ; r13 = 8 * COLINDEX

                add  r14, r13             ; r14 = rax + 16 + (8 * COLS * ROWINDEX) + (8 * COLINDEX), memory address of element

                push qword [r14]
                call output_int           ; print the int in rax

                add r15, 1                ; increment column iterator (inner loop)

                jmp printColumnLoop       ; jump back to start of inner loop

            printColumnLoopEnd:
                call output_newline
                add rdx, 1
                jmp printRowLoop

         printRowLoopEnd:       ; pop all of registers
            pop r13
            pop r14
            pop r15
            pop rdx
            pop rcx
            pop rbx
            pop rax

         pop  rbp                ; restore base pointer & return
         ret

;  --------------------------------------------------------------------------

matrix_mult:                    ; void matix_mult (matrix A, matrix B)

         push rbp                ; setup base pointer
         mov  rbp, rsp

         pop  rbp                ; restore base pointer & return
         ret


; ---------------------------------------------------------------------
;                    ADDITIONAL METHODS

CR      equ     13              ; carriage-return
LF      equ     10              ; line-feed
TAB     equ     9               ; tab
MINUS   equ     '-'             ; minus

LINUX   equ     80H             ; interupt number for entering Linux kernel
EXIT    equ     1               ; Linux system call 1 i.e. exit ()
WRITE   equ     4               ; Linux system call 4 i.e. write ()
STDOUT  equ     1               ; File descriptor 1 i.e. standard output

; ------------------------

os_return:
        mov  rax, EXIT          ; Linux system call 1 i.e. exit ()
        mov  rbx, 0             ; Error code 0 i.e. no errors
        int  LINUX              ; Interrupt Linux kernel

output_char:                    ; void output_char (ch)
        push rax
        push rbx
        push rcx
        push rdx
        push r8                ; r8..r11 are altered by Linux kernel interrupt
        push r9
        push r10
        push r11
        push qword [octetbuffer] ; (just to make output_char() re-entrant...)

        mov  rax, WRITE         ; Linux system call 4; i.e. write ()
        mov  rbx, STDOUT        ; File descriptor 1 i.e. standard output
        mov  rcx, [rsp+80]      ; fetch char from non-I/O-accessible segment
        mov  [octetbuffer], rcx ; load into 1-octet buffer
        lea  rcx, [octetbuffer] ; Address of 1-octet buffer
        mov  rdx, 1             ; Output 1 character only
        int  LINUX              ; Interrupt Linux kernel

        pop qword [octetbuffer]
        pop  r11
        pop  r10
        pop  r9
        pop  r8
        pop  rdx
        pop  rcx
        pop  rbx
        pop  rax
        ret

; ------------------------

output_newline:                 ; void output_newline ()
       push qword LF
       call output_char
       add rsp, 8
       ret

; ------------------------

output_tab:                     ; void output_tab ()
       push qword TAB
       call output_char
       add  rsp, 8
       ret

; ------------------------

output_minus:                   ; void output_minus()
       push qword MINUS
       call output_char
       add  rsp, 8
       ret

; ------------------------

output_int:                     ; void output_int (int N)
       push rbp
       mov  rbp, rsp

       ; rax=N then N/10, rdx=N%10, rbx=10

       push rax                ; save registers
       push rbx
       push rdx

       cmp  qword [rbp+16], 0 ; minus sign for negative numbers
       jge  L88

       call output_minus
       neg  qword [rbp+16]

L88:
       mov  rax, [rbp+16]       ; rax = N
       mov  rdx, 0              ; rdx:rax = N (unsigned equivalent of "cqo")
       mov  rbx, 10
       idiv rbx                ; rax=N/10, rdx=N%10

       cmp  rax, 0              ; skip if N<10
       je   L99

       push rax                ; output.int (N / 10)
       call output_int
       add  rsp, 8

L99:
       add  rdx, '0'           ; output char for digit N % 10
       push rdx
       call output_char
       add  rsp, 8

       pop  rdx                ; restore registers
       pop  rbx
       pop  rax
       pop  rbp
       ret


; ---------------------------------------------------------------------

segment .data

        ; Declare test matrices
matrixA DQ 2                    ; ROWS
        DQ 3                    ; COLS
        DQ 1, 2, 3              ; 1st row
        DQ 4, 5, 6              ; 2nd row

matrixB DQ 3                    ; ROWS
        DQ 2                    ; COLS
        DQ 1, 2                 ; 1st row
        DQ 3, 4                 ; 2nd row
        DQ 5, 6                 ; 3rd row

matrixC DQ 2                    ; ROWS
        DQ 2                    ; COLS
        DQ 0, 0                 ; space for ROWS*COLS ints
        DQ 0, 0                 ; (for filling in with matrixA*matrixB)

; ---------------------------------------------------------------------

; The following is used by output_char - do not disturb
; space in I/O-accessible segment for 1-octet output buffer
octetbuffer     DQ 0            ; (qword as choice of size on stack)
