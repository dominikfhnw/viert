; **** Codeword definitions ****

; first definition does not need a NEXT
DEF "EXIT", no_next
	rspop	FORTH_OFFSET

DEF "lit8"
	xor	eax, eax
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


DEF "swap"
	pop	ebx
	pop	eax
	push	ebx
	push	eax

DEF "dup"
%if 0
	pop	eax
	push	eax
	push	eax
%else
	push	dword [esp]
%endif

DEF "over"
	push	dword [esp+4]

DEF "drop"
	; try not to clobber eax with garbage
	pop	ebx

DEF "rot"
	pop	eax
	pop	ebx
	pop	ecx
	push	ebx
	push	eax
	push	ecx

%define BIGJMP 0
DEF "store"
	pop	ebx
	pop	dword [ebx] ; I have to agree with Kragen here, I'm also amazed this is legal

DEF "fetch"
	pop	ebx
	push	dword [ebx] ; This feels less illegal for some reason

DEF "cstore"
	pop	ebx
	pop	eax
	mov	[ebx], al

DEF "cfetch"
	pop	ebx
	xor	eax, eax
	mov	al, [ebx]

DEF "dupr2d"
	push	dword [ebp]

DEF "rspop"
	rspop	eax
	push	eax

DEF "rspush"
	%if 0
	pop	eax
	rspush	eax
	%else ; same amount of bytes, less instructions
	lea	ebp, [ebp-4]
	pop	dword [ebp] ; would be one byte less if !ebp
	%endif

;DEF "rsdec"
;	dec	dword [ebp]

DEF "rsinc"
	inc	dword [ebp]

DEF "zbranch"

	pop	ecx
	lodsb
	jecxz	A_NEXT
;DEF "branch", no_next
	;lodsb
	movsx	eax, al
	add	esi, eax

DEF "branch"
	lodsb
	movsx	eax, al
	add	esi, eax


; **** INIT BLOCK ****
NEXT


; TODO: merge with WORDVAL macro
%if WORD_TABLE
	%define BREAK 29
%else
	%define BREAK (END_OF_CODEWORDS - ASM_OFFSET + ELF_HEADER_SIZE)/WORD_ALIGN
%endif


A_DOCOL:
rspush	FORTH_OFFSET

%if !THRESH
	inc	eax
	inc	eax
%endif

xchg	eax, esi


A_NEXT:

%if !WORD_TABLE && WORD_SIZE == 2
	mov	eax, TABLE_OFFSET
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
			xor	eax, eax
			lodsWORD
			cmp	al, BREAK
			lea	eax, [eax*WORD_ALIGN+TABLE_OFFSET]
		%else
			mov	eax, TABLE_OFFSET
			lodsWORD
			cmp	al, BREAK
		%endif
		jae	A_DOCOL
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
		taint	eax
		set	NEXT_WORD, 0
		lodsWORD
		cmp	al, BREAK

		mov	eax, [STATIC_TABLE + 2*NEXT_WORD]
		cwde
		;add	eax, TABLE_OFFSET
		lea	eax, [eax + TABLE_OFFSET]
		jae	A_DOCOL
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

; **** END INIT ****

; f_while <imm8>:
;  1. decrement counter
;  2. if counter != 0:
;	jump imm8 bytes
DEF "while", no_next
%if 1
	dec	dword [ebp]
	;push	dword [ebp]

	;pop	ecx
	lodsb
	jz	A_NEXT
	movsx	eax, al
	add	esi, eax
	;rspop	eax
%elif 0
	dec	dword [ebp]
	movsx	eax, byte [esi]
	lodsb
	jz	A_NEXT
	add	esi, eax
%else
	dec	dword [ebp]
	;lodsb
	movsx	eax, byte [esi]
	jz	.end
	add	esi, eax
	.end:
	inc	esi
%endif


DEF "string"
	xor	eax,eax
	lodsb
	push	esi
	push	eax
	add	esi, eax

DEF "plus"
	pop	eax
	pop	ebx
	add	eax, ebx
	push	eax

DEF "negate"
	pop	eax
	neg	eax
	push	eax

DEF "dec"
	dec	dword [esp]

DEF "divmod"
	pop	ebx
	pop	eax
	xor	edx, edx
	div	ebx
	push	edx
	push	eax

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

DEF "int3"
	int3

NEXT
END_OF_CODEWORDS:
	%warning "BREAK" WORD_COUNT
	%if WORD_TABLE == 1 && WORD_COUNT != BREAK
		%fatal break constant set to wrong value: WORD_COUNT != BREAK
	%endif
