; **** Codeword definitions ****
%if WORD_TABLE
	%ifndef BREAK
	%define BREAK 24
	%endif
%else
	%define BREAK offset(END_OF_CODEWORDS-2)
%endif

%if 1
	%define assert_eax_low
	%define eax_tainted	xor eax, eax
%else
	%define assert_eax_low	xor eax, eax
	%define eax_tainted
%endif
; ABI
; esi:	Instruction pointer to next forth word
; edi:	Base pointer to executable segment. Tbd if needed
; esp:	Data stack
; ebp:	Return stack
; eax:	Contains value of forth word being executed.
;	Must be set =< 255 when returning from primitive
; edx:	First working register for primitives
; ecx:  Second working register for primitives, counter register
; ebx:	FORTH_OFFSET of calling function. Third working register
;
; Currently, f_syscall and f_rot are clobbering ebx.
;
;
; zero-eax vs before:
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
	push	dword [esp+4]
	END


%if 0
	DEF "dup"
		%if 1
			push	dword [esp]
			END
		%else
			pop	eax
			jmp	pusheax
			END no_next
		%endif

	DEF "rot"
		%if 0
			pop	edx
			pop	ebx
			pop	ecx
			push	ebx
			push	edx
			push	ecx
			END
		%else
			pop	edx
			pop	ecx
			pop	eax
			ush	ecx
			jmp	pushedxeax
			END no_next
		%endif
%endif

%if 1
	DEF "drop"
		pop	edx
		END
%endif

%if 1
; the minimal primitives
	DEF "store"
		pop	edx
		pop	dword [edx] ; I have to agree with Kragen here, I'm also amazed this is legal
		END

	DEF "fetch"
		pop	edx
		push	dword [edx] ; This feels less illegal for some reason
		END

	DEF "sp_at"
		push	esp
		END

	DEF "rp_at"
		push	RETURN_STACK
		END

	%if 0
	DEF "0lt"
		; from eForth. Would be 4 bytes smaller than my version
		; Unfortunately, it clashes with the eax <= 255 condition of this
		; Forth, making it just 3 bytes smaller
		pop	eax
		cdq		; sign extend AX into DX
		push	edx	; push 0 or -1
		xchg	eax, edx
		jmp	pusheax
		END	no_next
	%endif

	DEF "nand"
		pop	edx
		pop	eax
		and	eax, edx
		not	eax
		jmp	pusheax
		END	no_next

	%if !SYSCALL
	DEF "dupemit"
		; this leaves the stack alone, so technically its a dup and emit combined
		assert_eax_low
		rset	eax, -2
		taint	ebx, ecx, edx
		set	edx, 1
		set	eax, 4
		set	ebx, 1
		set	ecx, esp
		int	0x80
		; this will crash spectacularly if write was not successful (eax != 1)
		;eax_tainted
		END
		%endif

%endif

%if 0
	DEF "cstore"
		pop	ecx
		pop	edx
		mov	[ecx], dl
		END

	DEF "cfetch"
		pop	edx
		mov	al, [edx]
		END

%endif

%if 1
	DEF "rspush"
		%if 0
		pop	edx
		rspush	edx
		%else ; same amount of bytes, less instructions
		lea	RETURN_STACK, [RETURN_STACK-4]
		pop	dword [RETURN_STACK] ; would be one byte less if !ebp
		%endif
		END
%endif

A_DOCOL:
rspush	FORTH_OFFSET
mov	FORTH_OFFSET, ebx

A_NEXT:
assert_eax_low
lodsb
cmp	al, BREAK
lea	ebx, [eax*WORD_ALIGN+BASE]
ja	A_DOCOL
jmp	ebx

;DEF "0lt"
;	; from eForth. Would be 4 bytes smaller than my version
;	; Unfortunately, it clashes with the eax <= 255 condition of this
;	; Forth, making it just 3 bytes smaller
;	pop	eax
;	cdq		; sign extend AX into DX
;	push	edx	; push 0 or -1
;	xchg	eax, edx
;	jmp	pusheax
;	END	no_next

DEF "zbranch"
	pop	ecx
	jecxz	A_branch
	inc	FORTH_OFFSET
	END

%if 1
	DEF "branch"
		movsx	edx, byte [FORTH_OFFSET]
		add	FORTH_OFFSET, edx
		END
%endif

; f_while <imm8>:
;  1. decrement an unspecified loop counter
;  2. if counter != 0:
;	jump imm8 bytes
%if !FORTHWHILE
DEF "while2"
	assert_eax_low
	lodsb			; load jump offset
	dec	dword [RETURN_STACK]	; decrement loop counter

	jz	A_rdrop		; clean up return stack if we're finished
	;movsx	eax, al		; convert to -128..127 range
	sub	FORTH_OFFSET, eax
	END
%endif

DEF "rdrop"
	lea	RETURN_STACK, [RETURN_STACK+4]
	END

DEF "string"
	assert_eax_low
	lodsb
	push	FORTH_OFFSET
	push	eax
	add	FORTH_OFFSET, eax
	END

DEF "plus"
	pop	edx
	add	[esp], edx
	END

DEF "divmod"
	cdq		; eax is <= 255, so cdq will always work
	pop	ecx
	pop	eax
	div	ecx
pushedxeax:
	push	edx
pusheax:
	push	eax
	eax_tainted
	END

%if LIT8
DEF "lit8"
	assert_eax_low
	lodsb
	jmp	pusheax
	END no_next
%endif

DEF "lit32"
	lodsd
	jmp	pusheax
	END no_next

DEF "swap"
	pop	edx
	pop	eax
	jmp	pushedxeax
	END no_next

%if SYSCALL
DEF "syscall3"
	pop	eax
	pop	ebx
	pop	ecx
	pop	edx

	int	0x80
	jmp	pusheax
	END no_next

%else
DEF "exit"
	mov	al,1
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
