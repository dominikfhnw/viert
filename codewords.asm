; **** Codeword definitions ****

; first definition does not need a NEXT
DEF "EXIT", no_next
	rspop	FORTH_OFFSET

DEF "lit8"
	xor	eax, eax
	lodsb
	push	eax

DEF "lit16"
	lodsb
	mov	ah, al
	lodsb
	cwde
	push	eax

DEF "lit32"
	lodsd
	push	eax

DEF "sp_at"
	push	esp

%if 0
	DEF "upget8"
		mov	eax, [ebp]
		inc	dword [ebp]
		movzx	eax, byte [eax]
		push	eax

	DEF "upget32"
		mov	eax, [ebp]
		inc	dword [ebp]
		push	dword [eax]
%endif

DEF "plus"
	pop	eax
	pop	ebx
	add	eax, ebx
	push	eax

DEF "divmod"
	pop	ebx
	pop	eax
	xor	edx, edx
	div	ebx
	push	eax
	push	edx


DEF "swap"
	pop	ebx
	pop	eax
	push	ebx
	push	eax

DEF "dup"
	pop	eax
	push	eax
	push	eax

DEF "drop"
	; try not to clobber eax with garbage
	pop	ebx

%define BIGJMP 0
DEF "store"
	pop	ebx
	pop	dword [ebx] ; I have to agree with Kragen here, I'm also amazed this is legal

DEF "fetch"
	pop	ebx
	push	dword [ebx] ; This feels less illegal for some reason

DEF "negate"
	pop	eax
	neg	eax
	push	eax

%if 0
DEF "equ"
	pop	eax
	pop	ebx
	cmp	eax, ebx
	xor	eax, eax
	sete	al
	push	eax
%endif

DEF "zbranch"
	lodsb
	pop	ecx
	push	ecx
	jecxz	branch
;DEF "branch", no_next
	;lodsb
	movsx	eax, al
	add	esi, eax
	branch:
	;inc	esi
	
DEF "string"
	xor	eax,eax
	lodsb
	push	esi
	push	eax
	add	esi, eax

DEF "dec"
	dec	dword [esp]

%if 1
DEF "asmjmp"
	pop	eax
	pop	eax
	jmp	eax
%else

DEF "asmret"
	xor	eax,eax
	lodsb
	mov	ebx, esi
	add	esi, eax
	jmp	ebx
%endif

; asmret above does not directly return
DEF "syscall3", no_next
	pop	eax
	pop	ebx
	pop	ecx
	pop	edx
	int	0x80
	push	eax

NEXT
_start:
%include "init.asm"

%if !THRESH
	DEF "DOCOL", no_next
		rspush	FORTH_OFFSET
		inc	eax
		inc	eax
		xchg	eax, esi
%endif

A_NEXT:

; TODO: merge with WORDVAL macro
%if WORD_TABLE
	%define BREAK WORD_COUNT
%else
	%define BREAK ($ - ASM_OFFSET + ELF_HEADER_SIZE)/WORD_ALIGN
%endif

%if !WORD_TABLE && WORD_SIZE == 2
	mov	eax, TABLE_OFFSET
	lodsWORD
	cmp	al, BREAK
	jae	.docol
	jmp	eax
	%if WORD_ALIGN > 1
		%error not working atm
		;lea	NEXT_WORD, [WORD_ALIGN*NEXT_WORD+ASM_OFFSET]
	%endif

%elif !WORD_TABLE && WORD_SIZE == 1
	%if THRESH
		%if WORD_ALIGN > 1
			xor	eax, eax
			lodsWORD
			cmp	al, BREAK
			lea	eax, [eax*WORD_ALIGN+TABLE_OFFSET]
		%else
			mov	eax, TABLE_OFFSET
			lodsWORD
			cmp	al, BREAK
		%endif
		jae	.docol
		jmp	eax
	%else
		%if WORD_ALIGN > 1
			xor	eax, eax
			lodsWORD
			lea	eax, [eax*WORD_ALIGN+TABLE_OFFSET]
		%else
			mov	eax, TABLE_OFFSET
			lodsWORD
		%endif
		jmp	eax
	%endif
%elif WORD_SMALLTABLE
	%if THRESH
		set	NEXT_WORD, 0
		lodsWORD
		cmp	al, BREAK

		mov	eax, [STATIC_TABLE + 2*NEXT_WORD]
		cwde
		;add	eax, TABLE_OFFSET
		lea	eax, [eax + TABLE_OFFSET]
		jae	.docol
		jmp	eax

	%else
		set     NEXT_WORD, 0
		lodsWORD
		mov     eax, [STATIC_TABLE + 2*NEXT_WORD]
		cwde
		add     eax, TABLE_OFFSET
		jmp	eax

	%endif
%else
	%error unhandled case
%endif

.docol:
	rspush	FORTH_OFFSET
	xchg	eax, esi
	jmp	A_NEXT
