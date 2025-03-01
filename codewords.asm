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

DEF "sp_at"
	push	esp
	END

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

DEF "drop"
	pop	edx
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

%define BIGJMP 0
%if 0

DEF "store"
	pop	edx
	pop	dword [edx] ; I have to agree with Kragen here, I'm also amazed this is legal
	END

DEF "fetch"
	pop	edx
	push	dword [edx] ; This feels less illegal for some reason
	END

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

DEF "rspush"
	%if 0
	pop	edx
	rspush	edx
	%else ; same amount of bytes, less instructions
	lea	RETURN_STACK, [RETURN_STACK-4]
	pop	dword [RETURN_STACK] ; would be one byte less if !ebp
	%endif
	END

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

%if 0
DEF "branchstack"
	;movsx	edx, byte [FORTH_OFFSET]
	pop	edx
	add	FORTH_OFFSET, edx
	END

DEF "upget"
	xchg	FORTH_OFFSET, ebx
	lodsb
	xchg	FORTH_OFFSET, ebx
	END

DEF "upbranch"
	xchg	FORTH_OFFSET, ebx
	lodsb
	xchg	FORTH_OFFSET, ebx
	add	FORTH_OFFSET, eax
	END

DEF "upget"
	xchg	FORTH_OFFSET, [RETURN_STACK]
	lodsb
	xchg	FORTH_OFFSET, [RETURN_STACK]
	;nop
	;mov	edx, [RETURN_STACK]
	;movzx	ecx, byte [edx+1]
	;inc	dword [RETURN_STACK]
	END

DEF "while3"
	lodsb			; load jump offset
	dec	dword [RETURN_STACK]	; decrement loop counter

	jz	A_rdrop		; clean up return stack if we're finished
	;movsx	eax, al		; convert to -128..127 range
	sub	FORTH_OFFSET, eax
	END

DEF "branchf"
	lodsb
	add	FORTH_OFFSET, eax
	END

DEF "branchb"
	lodsb
	sub	FORTH_OFFSET, eax
	END

DEF "zbranchf"
	lodsb
	pop	ecx
	jecxz	A_NEXT
	add	FORTH_OFFSET, eax
	END

DEF "zbranchb"
	lodsb
	pop	ecx
	jecxz	A_NEXT
	add	FORTH_OFFSET, eax
	END

DEF "zbranch2"
	lodsb
	pop	ecx
	jecxz	A_NEXT
	movsx	edx, al
	add	FORTH_OFFSET, edx
	END

DEF "zbranch4"
	;lodsb
	pop	ecx
	jecxz	A_NEXT
	movsx	edx, byte [FORTH_OFFSET]
	add	FORTH_OFFSET, edx
	END


DEF "upget8"
	mov	eax, [ebp]
	inc	dword [ebp]
	movzx	eax, byte [eax]
	push	eax
	END

DEF "upget32"
	mov	eax, [ebp]
	inc	dword [ebp]
	push	dword [eax]
	END
%endif

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

%if 1
DEF "bool"
	pop	ecx
	jecxz	.zero
	or	ecx, -1
	.zero:
	push	ecx
	END

DEF "bool2"
        pop	ecx
	test	ecx, ecx
	setnz	al                ; AL=0 if ZF=1, else AL=1
	dec	eax                  ; AL=ff if AL=0, else AL=0
	;cbw                     ; AH=AL
	push eax
	END
%endif

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
	END

;DEF "negate"
;	neg	dword [esp]

DEF "not"
	not	dword [esp]
	END

;DEF "not2"
;	pop	eax
;	not	eax
;	jmp	pusheax
;	END no_next

DEF "and"
	pop	edx
	and	[esp], edx
	END

DEF "or"
	pop	edx
	or	[esp], edx
	END

DEF "nand"
	pop	edx
	pop	eax
	and	eax, edx
	not	eax
	jmp	pusheax
	END no_next

%if 0
DEF "dec"
	dec	dword [esp]
	END

DEF "inc"
	inc	dword [esp]
	;pop	edx
	;inc	edx
	;push	edx
	END
%endif

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

%if 0
DEF "int3"
	int3
	END
%endif

DEF "lit8"
	lodsb
	jmp	pusheax
	END no_next

%if 0
DEF "lit16"
	lodsb
	mov	ah, al
	lodsb
	cwde
	jmp	pusheax
	END no_next
%endif

DEF "lit32"
	lodsd
	jmp	pusheax
	END no_next


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
	jmp	pusheax
	END no_next


%if 0
DEF "asmjmp"
	pop	edx
	pop	edx
	jmp	edx
	END no_next
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
