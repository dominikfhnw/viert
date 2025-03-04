; **** Codeword definitions ****
%if WORD_TABLE
	%ifndef BREAK
	%define BREAK 24
	%endif
%else
	%define BREAK offset(END_OF_CODEWORDS)
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

; first definition does not need a NEXT
DEF "EXIT"
	rspop	FORTH_OFFSET
	END

%if 1
DEF "swap"
%if 0
	pop	ecx
	pop	edx
	push	ecx
	push	edx
	END
%else
	pop	edx
	pop	eax
	jmp	pushedxeax
	END no_next
%endif
%endif

%if 0
DEF "dbg"
	;mov	eax, [esp]
	;taint	eax, ebx, ecx, edx
	;printnum
	;set	eax, 0
	reg

	END
DEF "dup"
%if 1
	push	dword [esp]
	END
%else
	pop	eax
	jmp	pusheax
	END no_next
%endif

DEF "over"
	push	dword [esp+4]
	END

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
	push	ecx
	jmp	pushedxeax
	END no_next
%endif
%endif

DEF "drop"
	pop	edx
	END


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

DEF "nand"
	pop	edx
	pop	eax
	and	eax, edx
	not	eax
	jmp	pusheax
	END	no_next

DEF "dupemit"
	; this leaves the stack alone, so technically its a dup and emit combined
	rset	eax, -2
	taint	ebx, ecx, edx
	set	edx, 1
	set	eax, 4
	set	ebx, 1
	set	ecx, esp
	int	0x80
	; this will crash spectacularly if write was not successful (eax != 1)
	END

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

%if 0
DEF "dupr2d"
	push	dword [RETURN_STACK]
	END

DEF "rspop"
	rspop	edx
	push	edx
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

;DEF "rsdec"
;	dec	dword [RETURN_STACK]
;END

;DEF "rsinc"
;	inc	dword [RETURN_STACK]
;END

; **** INIT BLOCK ****

A_DOCOL:
rspush	FORTH_OFFSET

%if !THRESH
	inc	ebx
	inc	ebx
%endif

mov	FORTH_OFFSET, ebx


A_NEXT:

%if !WORD_TABLE && WORD_SIZE == 4
	lodsWORD
	cmp	eax, (ORG + BREAK)
	jae	A_DOCOL
	jmp	eax
	%if WORD_ALIGN > 1
		%error not working atm
		;lea	NEXT_WORD, [WORD_ALIGN*NEXT_WORD+ASM_OFFSET]
	%endif

%elif !WORD_TABLE && WORD_SIZE == 2
	mov	eax, BASE
	lodsWORD
	cmp	ax, BREAK
	jae	A_DOCOL
	jmp	eax
	%if WORD_ALIGN > 1
		%error not working atm
		;lea	NEXT_WORD, [WORD_ALIGN*NEXT_WORD+ASM_OFFSET]
	%endif

%elif !WORD_TABLE && WORD_SIZE == 1
	lodsWORD
	cmp	al, BREAK
	lea	ebx, [eax*WORD_ALIGN+BASE]
	jae	A_DOCOL
	jmp	ebx
%elif WORD_SMALLTABLE
	%if THRESH
		lodsWORD
		movzx	ebx, word [STATIC_TABLE + 2*NEXT_WORD]
		add	ebx, BASE
		cmp	al, BREAK
		jae	A_DOCOL
		jmp	ebx

	%else
		%fatal broken
		set     NEXT_WORD, 0
		lodsWORD
		mov     eax, [STATIC_TABLE + 2*NEXT_WORD]
		cwde
		add     ebx, BASE
		jmp	ebx

	%endif
%else ; table with 4 byte offsets
	%if THRESH
		lodsWORD
		cmp	al, BREAK
		; small
		%if 1
			mov	ebx, [STATIC_TABLE + 4*NEXT_WORD]
			jae	A_DOCOL
			jmp	ebx
		; fast
		; TODO: broken
		%else
			;%fatal broken
			jae	.docol
			jmp	[STATIC_TABLE + 4*NEXT_WORD]
			.docol:
			rspush	FORTH_OFFSET
			mov	FORTH_OFFSET, [STATIC_TABLE + 4*NEXT_WORD]
			NEXT
		%endif

	%else
		%error unhandled case
	%endif
%endif

; **** END INIT ****

DEF "zbranch"
	pop	ecx
	jecxz	A_branch
	inc	FORTH_OFFSET
	END

DEF "branch"
	movsx	edx, byte [FORTH_OFFSET]
	add	FORTH_OFFSET, edx
	END

; f_while <imm8>:
;  1. decrement an unspecified loop counter
;  2. if counter != 0:
;	jump imm8 bytes
DEF "while2"
	lodsb			; load jump offset
	dec	dword [RETURN_STACK]	; decrement loop counter

	jz	A_rdrop		; clean up return stack if we're finished
	;movsx	eax, al		; convert to -128..127 range
	sub	FORTH_OFFSET, eax
	END

DEF "rdrop"
	lea	RETURN_STACK, [RETURN_STACK+4]
	END

DEF "string"
	lodsb
	push	FORTH_OFFSET
	push	eax
	add	FORTH_OFFSET, eax
	END

DEF "plus"
	pop	edx
	add	[esp], edx
	END

;DEF "not"
;	not	dword [esp]
;	END

DEF "divmod"
	cdq		; eax is <= 255, so cdq will always work
	pop	ecx
	pop	eax
	div	ecx
pushedxeax:
	push	edx
pusheax:
	push	eax
	xor	eax, eax
	END

%if LIT8
DEF "lit8"
	lodsb
	jmp	pusheax
	END no_next
%endif

DEF "lit32"
	lodsd
	jmp	pusheax
	END no_next


%if 0
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
	int3
	END no_next
	%endif

END_OF_CODEWORDS:
	%warning "BREAK" WORD_COUNT
	%assign SIZE END_OF_CODEWORDS - $$
	%warning "SIZE" SIZE
	%if WORD_TABLE == 1 && WORD_COUNT != BREAK
		%fatal break constant set to wrong value: WORD_COUNT != BREAK
	%endif
