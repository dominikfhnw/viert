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
DEF "EXIT", no_next
	rspop	FORTH_OFFSET

DEF "lit8"
	lodsb
	push	eax

%if 0
DEF "lit16"
	lodsb
	mov	ah, al
	lodsb
	cwde
	push	eax
%endif

DEF "lit32"
	lodsd
	push	eax
	xor	eax, eax

DEF "sp_at"
	push	esp

DEF "swap"
	pop	ecx
	pop	edx
	push	ecx
	push	edx

DEF "dup"
	push	dword [esp]

DEF "over"
	push	dword [esp+4]

DEF "drop"
	pop	edx

DEF "rot"
	pop	edx
	pop	ebx
	pop	ecx
	push	ebx
	push	edx
	push	ecx

%define BIGJMP 0
DEF "store"
	pop	edx
	pop	dword [edx] ; I have to agree with Kragen here, I'm also amazed this is legal

DEF "fetch"
	pop	edx
	push	dword [edx] ; This feels less illegal for some reason

DEF "cstore"
	pop	ecx
	pop	edx
	mov	[ecx], dl

DEF "cfetch"
	pop	edx
	mov	al, [edx]

%if 0
DEF "dupr2d"
	push	dword [RETURN_STACK]
%endif

DEF "rspop"
	rspop	edx
	push	edx

DEF "rspush"
	%if 0
	pop	edx
	rspush	edx
	%else ; same amount of bytes, less instructions
	lea	RETURN_STACK, [RETURN_STACK-4]
	pop	dword [RETURN_STACK] ; would be one byte less if !ebp
	%endif

;DEF "rsdec"
;	dec	dword [RETURN_STACK]

DEF "rsinc"
	inc	dword [RETURN_STACK]

; **** INIT BLOCK ****
NEXT

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
	%if THRESH
		%if WORD_ALIGN > 1
			lodsWORD
			cmp	al, BREAK
			lea	ebx, [eax*WORD_ALIGN+BASE]
		%else
			%fatal not working
			mov	eax, BASE
			lodsWORD
			cmp	al, BREAK
		%endif
		jae	A_DOCOL
		jmp	ebx
	%else
		%if WORD_ALIGN > 1
			lodsWORD
			lea	ebx, [eax*WORD_ALIGN+BASE]
		%else
			%fatal not working
			mov	eax, BASE
			lodsWORD
		%endif
		jmp	ebx
	%endif
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

DEF "zbranch", no_next
	pop	ecx
	jecxz	A_branch
	inc	FORTH_OFFSET

DEF "branch"
	movsx	edx, byte [FORTH_OFFSET]
	add	FORTH_OFFSET, edx

;DEF "branch32"
;	add	FORTH_OFFSET, [FORTH_OFFSET]

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

DEF "rdrop"
	lea	RETURN_STACK, [RETURN_STACK+4]


DEF "string"
	lodsb
	push	FORTH_OFFSET
	push	eax
	add	FORTH_OFFSET, eax

DEF "plus"
%if 0
	pop	edx
	pop	ecx
	add	edx, ecx
	push	edx
%else
	pop	edx
	add	[esp], edx
%endif

DEF "negate"
	neg	dword [esp]

DEF "dec"
	dec	dword [esp]

DEF "inc"
	inc	dword [esp]
	;pop	edx
	;inc	edx
	;push	edx

DEF "divmod"
	cdq
	pop	ecx
	pop	eax
	div	ecx
	push	edx
	push	eax
	xor	eax, eax

DEF "int3"
	int3


DEF "syscall3"
%if 0
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
%else
	pop	eax
	pop	ebx
	pop	ecx
	pop	edx
%endif

	int	0x80
	push	eax
	xor	eax, eax

%if 1
DEF "asmjmp"
	pop	edx
	pop	edx
	jmp	edx
%else

;DEF "asmret"
;	xor	eax,eax
;	lodsb
;	mov	edx, FORTH_OFFSET
;	add	FORTH_OFFSET, eax
;	jmp	edx
%endif

END_OF_CODEWORDS:
	%warning "BREAK" WORD_COUNT
	%if WORD_TABLE == 1 && WORD_COUNT != BREAK
		%fatal break constant set to wrong value: WORD_COUNT != BREAK
	%endif
