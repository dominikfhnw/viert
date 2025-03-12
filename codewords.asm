; **** Codeword definitions ****
%if WORD_TABLE
	%ifndef BREAK
	%define BREAK 24
	%endif
%else
	%define BREAK offset(END_OF_CODEWORDS-2)
%endif

%if 1
	; Nb: xor eax, eax also clears upper 32bits on 64bit
	%define assert_A_low
	%define A_tainted	xor eax, eax
%else
	%define assert_A_low	xor eax, eax
	%define A_tainted
%endif
; ABI
; esi:	Instruction pointer to next forth word
; SP:	Data stack
; DI:	Return stack
; A:	Contains value of forth word being executed.
;	Must be set =< 255 when returning from primitive
; D:	First working register for primitives
; C:	Second working register for primitives, counter register
; B:	FORTH_OFFSET of calling function. Third working register
;
; SP and DI are macros that expand to esp and edi on "32" and "x32" targets.
; They expand to rsp and rdi on target "64"
; Instruction pointer is always esi - we do not support programs bigger than 2^32 bytes
;
; Ideas what to use rbp for:
; * address of next (nope: disp8 encoding means 3 bytes)
; * zero register   (nope: mov is same or more than xor)
; * comparison register
; * counter register: only gain is not having to have rdrop
;
; Ideas for r8-15:
; * Keep part of stack
; * debug registers
;
;
; zero-A vs before:
; lit32:	+2
; divmod:	+1
; syscall3:	+2
; DOCOL:	+1
; lit8:		-2
; NEXT:		-3
; while2:	-2
; string:	-2
; TOTAL:	-3

%if FORCE_ARITHMETIC_32
	%define	aD	edx
	%define	aC	ecx
	%define	aB	ebx
	%define arith	dword
%else
	%define	aD	D
	%define	aC	C
	%define	aB	B
	%define arith	native
%endif

DEF "EXIT"
	rspop	FORTH_OFFSET
	END

DEF "over"
	push	native [SP+CELL_SIZE]
	END


%if 0
	DEF "dup"
		%if 1
			push	native [SP]
			END
		%else
			pop	A
			END	pushA
		%endif
%endif

DEF "drop"
	pop	D
	END

%if 1
; the minimal primitives
	DEF "store"
		pop	D
		pop	native [D] ; I have to agree with Kragen here, I'm also amazed this is legal
		END

	DEF "fetch"
		pop	D
		push	native [D] ; This feels less illegal for some reason
		END

	DEF "sp_at"
		push	SP
		END

	DEF "rp_at"
		push	RETURN_STACK
		END

	%if 0
	DEF "0lt"
		; from eForth. Would be 4 bytes smaller than my version
		; Unfortunately, it clashes with the A <= 255 condition of this
		; Forth, making it just 3 bytes smaller
		pop	A
		cdq		; sign extend AX into DX
		push	D	; push 0 or -1
		xchg	A, D
		END	pushA
	%endif

	DEF "nand"
		pop	aD
		and	[SP], aD
		END	no_next
	DEF "not"
		not	arith [SP]
		END

	%if !SYSCALL
	DEF "dupemit"
		; this leaves the stack alone, so technically its a dup and emit combined
		assert_A_low
		rset	eax, -2
		taint	ebx, ecx, edx
		set	edx, 1
		set	eax, SYS_write
		set	ebx, 1
		set	ecx, esp
		int	0x80
		; this will crash spectacularly if write was not successful (A != 1)
		;A_tainted
		;xor	eax, eax
		END
		%endif

%endif

%if 0
	DEF "cstore"
		pop	C
		pop	D
		mov	[C], dl
		END

	DEF "cfetch"
		pop	D
		mov	al, [D]
		END

%endif

%if 1
	DEF "rspush"
		lea	RETURN_STACK, [embiggen(RETURN_STACK)-CELL_SIZE]
		pop	native [embiggen(RETURN_STACK)]
		END
%endif

%if SYSCALL64 && 0
DEF "emit64b"
	push	rdi
	push	rsi

	cdq
	inc	edx
	mov	eax, edx
	mov	edi, edx
	lea	rsi, [rsp+CELL_SIZE*2]

	syscall
	pop	rsi
	pop	rdi
	pop	rdx	; equivalent to drop
	END

DEF "emit32b"
	assert_A_low
	rset	eax, -2
	taint	ebx, ecx, edx
	set	edx, 1
	set	eax, SYS_write
	set	ebx, 1
	set	ecx, esp
	int	0x80
	pop	edx	; equivalent to drop
	END

%endif

A_DOCOL:
rspush	FORTH_OFFSET
mov	FORTH_OFFSET, ebx

A_NEXT:
assert_A_low
lodsb
cmp	al, BREAK
; we assume code size < 2^32
lea	ebx, [A*WORD_ALIGN+BASE]
ja	A_DOCOL
jmp	B

;DEF "0lt"
;	; from eForth. Would be 4 bytes smaller than my version
;	; Unfortunately, it clashes with the A <= 255 condition of this
;	; Forth, making it just 3 bytes smaller
;	pop	A
;	cdq		; sign extend AX into DX
;	push	D	; push 0 or -1
;	xchg	A, D
;	jmp	pushA
;	END	no_next

DEF "zbranch"
	pop	C
	jCz	A_branch
	lodsb	; inc esi, but smaller on 64bit
	END

%if 1
	DEF "branch"
		movsx	edx, byte [embiggen(FORTH_OFFSET)]
		add	FORTH_OFFSET, edx
		END
%endif

; XXX keep?
DEF "loopdec"
	dec	arith [embiggen(RETURN_STACK)]	; decrement loop counter
	push	native [embiggen(RETURN_STACK)]
	END

; f_while <imm8>:
;  1. decrement an unspecified loop counter
;  2. if counter != 0:
;	jump imm8 bytes
%if !FORTHWHILE
DEF "while2"
	assert_A_low
	lodsb			; load jump offset
	dec	arith [embiggen(RETURN_STACK)]	; decrement loop counter

	jz	A_rdrop		; clean up return stack if we're finished
	;movsx	A, al		; convert to -128..127 range
	sub	FORTH_OFFSET, eax
	END
%endif

DEF "rdrop"
	lea	RETURN_STACK, [embiggen(RETURN_STACK)+CELL_SIZE]
	END

DEF "string"
	assert_A_low
	lodsb
	push	FORTH_OFFSET
	push	A
	add	FORTH_OFFSET, eax
	END

DEF "plus"
	pop	D
	add	[SP], aD
	END

DEF "divmod"
	cdq		; A is <= 255, so cdq will always work
	pop	C
	pop	A
	div	aC
pushDA:
	push	D
pushA:
	push	A
	A_tainted
	END

%if LIT8
DEF "lit8"
	assert_A_low
	lodsb
	END	pushA
%endif

DEF "lit32"
	lodsd
	END	pushA

%if BIT_ARITHMETIC == 64
DEF "lit64"
	lodsq
	END	pushA
%endif

DEF "swap"
	pop	D
	pop	A
	END	pushDA

DEF "rot"
	pop	D
	pop	C
	pop	A
	push	C
	END	pushDA

%if SYSCALL
%if !SYSCALL64
DEF "syscall3"
	pop	A
	pop	B
	pop	C
	pop	D

	int	0x80
	END	pushA

%else
; x64 syscall: syscall number in rax
; params: rdi, rsi, rdx, r10, r8, r9
; para32: ebx, ecx, edx, ...
; num...: 1    2    3
; clobbered: rax, rcx, r11
; we got to save rdi and rsi
; free: rbx, rbp(?), r12, r13, r14, r15
DEF "syscall3"
	push	rdi
	pop	rbp
	mov	ebx, esi

	pop	rax
	pop	rdi
	pop	rsi
	pop	rdx

	syscall
	mov	esi, ebx
	push	rbp
	pop	rdi
	END	pushA
%endif

%else
DEF "bye"
	mov	al, SYS_exit
	int	0x80
	END	no_next
	%endif

%if DEBUG
DEF "dbg"
	reg
	END
DEF "int3"
	int3
	END
%else
	%define f_dbg
	%define f_int3
%endif

A___BREAK__:
END_OF_CODEWORDS:
%warning "BREAK" WORD_COUNT
%assign SIZE END_OF_CODEWORDS - $$
%warning "SIZE" SIZE
%if WORD_TABLE == 1 && WORD_COUNT != BREAK
	%fatal break constant set to wrong value: WORD_COUNT != BREAK
%endif
