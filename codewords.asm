; **** Codeword definitions ****
%if WORD_TABLE
	%ifndef BREAK
	%define BREAK 24
	%endif
%else
	%define BREAK offset(END_OF_CODEWORDS-2)
%endif

%if 1
	%define assert_A_low
	%define A_tainted	xor A, A
%else
	%define assert_A_low	xor A, A
	%define A_tainted
%endif
; ABI
; SI:	Instruction pointer to next forth word
; DI:	Base pointer to executable segment. Tbd if needed
; SP:	Data stack
; BP:	Return stack
; A:	Contains value of forth word being executed.
;	Must be set =< 255 when returning from primitive
; D:	First working register for primitives
; C:  Second working register for primitives, counter register
; B:	FORTH_OFFSET of calling function. Third working register
;
; Currently, f_syscall and f_rot are clobbering B.
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
			jmp	pushA
			END no_next
		%endif

	DEF "rot"
		%if 0
			pop	D
			pop	B
			pop	C
			push	B
			push	D
			push	C
			END
		%else
			pop	D
			pop	C
			pop	A
			ush	C
			jmp	pushDA
			END no_next
		%endif
%endif

%if 1
	DEF "drop"
		pop	D
		END
%endif

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
		jmp	pushA
		END	no_next
	%endif

	DEF "nand"
		pop	D
		and	[SP], D
		reg
		END	no_next
	DEF "not"
		not	native [SP]
		reg
		END

	%if !SYSCALL
	DEF "dupemit"
		; this leaves the stack alone, so technically its a dup and emit combined
		assert_A_low
		rset	A, -2
		taint	B, C, D
		set	D, 1
		set	A, SYS_write
		set	B, 1
		set	C, SP
		int	0x80
		; this will crash spectacularly if write was not successful (A != 1)
		;A_tainted
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
		%if 0
		pop	D
		rspush	D
		%else ; same amount of bytes, less instructions
		lea	RETURN_STACK, [RETURN_STACK-CELL_SIZE]
		pop	native [RETURN_STACK] ; would be one byte less if !BP
		%endif
		END
%endif

A_DOCOL:
rspush	FORTH_OFFSET
mov	FORTH_OFFSET, B

A_NEXT:
assert_A_low
lodsb
cmp	al, BREAK
lea	B, [A*WORD_ALIGN+BASE]
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
	inc	FORTH_OFFSET
	END

%if 1
	DEF "branch"
		movsx	D, byte [FORTH_OFFSET]
		add	FORTH_OFFSET, D
		END
%endif

; XXX keep?
DEF "loopdec"
	dec	native [RETURN_STACK]	; decrement loop counter
	push	native [RETURN_STACK]
	END

; f_while <imm8>:
;  1. decrement an unspecified loop counter
;  2. if counter != 0:
;	jump imm8 bytes
%if !FORTHWHILE
DEF "while2"
	assert_A_low
	lodsb			; load jump offset
	dec	native [RETURN_STACK]	; decrement loop counter

	jz	A_rdrop		; clean up return stack if we're finished
	;movsx	A, al		; convert to -128..127 range
	sub	FORTH_OFFSET, A
	END
%endif

DEF "rdrop"
	lea	RETURN_STACK, [RETURN_STACK+CELL_SIZE]
	END

DEF "string"
	assert_A_low
	lodsb
	push	FORTH_OFFSET
	push	A
	add	FORTH_OFFSET, A
	END

DEF "plus"
	pop	D
	add	[SP], D
	END

DEF "divmod"
	cdq		; A is <= 255, so cdq will always work
	pop	C
	pop	A
	div	C
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
	jmp	pushA
	END no_next
%endif

DEF "lit32"
	lodsd
	jmp	pushA
	END no_next

DEF "swap"
	pop	D
	pop	A
	jmp	pushDA
	END no_next

%if SYSCALL
DEF "syscall3"
	pop	A
	pop	B
	pop	C
	pop	D

	int	0x80
	jmp	pushA
	END no_next

%else
DEF "exit"
	mov	al, SYS_exit
	int	0x80
	END no_next
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

END_OF_CODEWORDS:
%warning "BREAK" WORD_COUNT
%assign SIZE END_OF_CODEWORDS - $$
%warning "SIZE" SIZE
%if WORD_TABLE == 1 && WORD_COUNT != BREAK
	%fatal break constant set to wrong value: WORD_COUNT != BREAK
%endif
