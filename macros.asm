; **** Macros ****
%ifndef BIGJMP
%define BIGJMP 1
%endif

%macro NEXT arg(0)
	;%if JUMPNEXT
	%if BIGJMP
		;jmp    [edi + offset(ASM_OFFSET)]
		jmp    [edi]
		;jmp A_NEXT
	%else
		jmp short A_NEXT
	%endif
	;%else
	;	realNEXT
	;%endif
%endmacro

%macro realNEXT 0
	%%next:
	%if !WORD_TABLE && WORD_SIZE == 4
		%if WORD_FOOBEL
			; + just a single register for NEXT
			; - a bit bigger than the other solution
			lea	FORTH_OFFSET, [FORTH_OFFSET+4]
			jmp	[FORTH_OFFSET]
		%else
			lodsWORD
			jmp	NEXT_WORD
		%endif
	%elif !WORD_TABLE && WORD_SIZE == 2
		%if 0
			movzx	NEXT_WORD, word [FORTH_OFFSET]
			add	NEXT_WORD, TABLE_OFFSET
			;add	FORTH_OFFSET, WORD_SIZE
			inc	FORTH_OFFSET
			inc	FORTH_OFFSET
			jmp	NEXT_WORD
		%else
			mov	eax, TABLE_OFFSET
			lodsWORD
			%if WORD_ALIGN > 1
				%error not working atm
				;lea	NEXT_WORD, [WORD_ALIGN*NEXT_WORD+ASM_OFFSET]
			%endif
			jmp	NEXT_WORD
		%endif

	%elif !WORD_TABLE && WORD_SIZE == 1
		%if WORD_ALIGN > 1
			;%error not working atm
			;lea	NEXT_WORD, [WORD_ALIGN*NEXT_WORD+ASM_OFFSET]
			xor	eax, eax
			;mov	eax, TABLE_OFFSET
			lodsWORD
			;imul	eax, eax, WORD_ALIGN
			;add	eax, TABLE_OFFSET
			lea	eax, [eax*WORD_ALIGN+TABLE_OFFSET]
			jmp	NEXT_WORD
		%else
			mov	eax, TABLE_OFFSET
			lodsWORD
			jmp	NEXT_WORD
		%endif
	%elif WORD_SMALLTABLE
		;mov	eax, TABLE_OFFSET
		;lodsWORD
		;%if WORD_ALIGN > 1
		;	%error not working atm
		;	;lea	NEXT_WORD, [WORD_ALIGN*NEXT_WORD+ASM_OFFSET]
		;%endif
		;jmp	NEXT_WORD
		
		%if 0
			set	NEXT_WORD, 0
			lodsWORD
			movzx	eax, al
			%define OFF (STATIC_TABLE - $$ + ELF_HEADER_SIZE)
			movzx	NEXT_WORD, word [TABLE_OFFSET + 2*NEXT_WORD + OFF]
			add	NEXT_WORD, TABLE_OFFSET
			jmp	NEXT_WORD
		%elif 1
			set	NEXT_WORD, 0
			lodsWORD
			%define OFF (STATIC_TABLE - $$ + ELF_HEADER_SIZE)
			;mov	eax, [TABLE_OFFSET + 2*NEXT_WORD + OFF]
			;mov	ax, [TABLE_OFFSET + 2*NEXT_WORD + OFF]
			;mov	ax, [STATIC_TABLE + 2*NEXT_WORD]

			movzx	eax, word [STATIC_TABLE + 2*NEXT_WORD]
			;movzx	eax, word [TABLE_OFFSET + 2*NEXT_WORD + OFF]

			add	NEXT_WORD, TABLE_OFFSET
			jmp	NEXT_WORD

		%elif 0
			;mov	NEXT_WORD, edi
			set	NEXT_WORD, 0
			lodsWORD
			;cbw
			;cwde
			;movzx	eax, byte [esi]
			;inc	esi
			;add	eax, al
			;push	ax
			;add	eax, eax
			;add	eax, STATIC_TABLE
			;movzx	eax, al
			%define OFF (STATIC_TABLE - $$ + ELF_HEADER_SIZE)
			mov	eax, [STATIC_TABLE + 2*NEXT_WORD]
			;mov	eax, [edi+2*eax+OFF]
			cwde
			;movzx	eax, word [TABLE_OFFSET + 2*NEXT_WORD + OFF]
			add	eax, TABLE_OFFSET
			;mov	ax, [TABLE_OFFSET + 2*NEXT_WORD + OFF]
			;mov	ax, [STATIC_TABLE + 2*NEXT_WORD]

			;set	eax, edi
			;movzx	eax, word [STATIC_TABLE + 2*NEXT_WORD]

			;add	NEXT_WORD, TABLE_OFFSET
			jmp	NEXT_WORD

		%else	; striped table
			mov	ecx, edi
			lodsWORD
			push	eax
			;mov	ebx, STATIC_TABLE
			mov	ebx, edi
			mov	bl, 0xA4
			xlat
			mov	cl, al
			inc	bh
			pop	eax
			xlat
			mov	ch, al
			jmp	ecx
		%endif
;		;mov	ax, word [TABLE_OFFSET + 2*NEXT_WORD]


;		%ifnidn NEXT_WORD,eax
;			%error NEXT__WORD is not eax
;		%endif
;		%if WORD_SIZE == 1
;			set	NEXT_WORD, 0
;		%endif
;		lodsWORD
;		%if WORD_SIZE == 2
;			cwde
;		%endif
;		;mov	ax, word [TABLE_OFFSET + 2*NEXT_WORD]
;		movzx	eax, word [TABLE_OFFSET + 2*NEXT_WORD]
;		%if 1
;			add	NEXT_WORD, DEF0
;			jmp	NEXT_WORD
;		%else
;			jmp	[NEXT_WORD + DEF0]
;		%endif
;		;DIRECT_EXECUTE reg
	%elif 0
		;movzx	NEXT_WORD, byte [FORTH_OFFSET]
		;inc	FORTH_OFFSET
		set	NEXT_WORD, 0
		lodsWORD
		push	dword [TABLE_OFFSET + 4*NEXT_WORD]
		;taint	NEXT_WORD
		ret
	%elif 0
		; + freely choose which registers to use
		; - every NEXT is 1 byte longer
		movzx	NEXT_WORD, WORD_TYPE [FORTH_OFFSET]
		inc	FORTH_OFFSET
		taint	NEXT_WORD
		jmp	[TABLE_OFFSET + 4*NEXT_WORD]
	%else
		%ifnidn NEXT_WORD,eax
			%error NEXT__WORD is not eax
		%endif
		%if WORD_SIZE == 1
			set	NEXT_WORD, 0
		%endif
		lodsWORD
		%if WORD_SIZE == 2
			cwde
		%endif
		%if 1
			jmp	[TABLE_OFFSET + 4*NEXT_WORD]
		%else
			mov	eax, [TABLE_OFFSET + 4*NEXT_WORD]
			jmp	eax
		%endif
	%endif
	;mov	NEXT_WORD, [TABLE_OFFSET + 4*NEXT_WORD]
	;lea	NEXT_WORD, [TABLE_OFFSET + 4*NEXT_WORD]
	;jmp	NEXT_WORD
	;jmp	[NEXT_WORD]

%endmacro

%macro DEF 1-2.nolist
	%if %0 == 1
		NEXT
	%endif
	align WORD_ALIGN, nop
	; objdump prints the lexicographical smallest label. change A to E
	; or something to get the DEFn labels
	DEF%[WORD_COUNT]:
	A_%tok(%1):
	%define %[n_%tok(%1)] %[WORD_COUNT]
	%define %[f_%tok(%1)] WORD %[WORD_COUNT]
	%warning NEW DEFINITION: DEF%[WORD_COUNT] %1
	;%define %[%tok(%1)] WORD %[WORD_COUNT]
	rtaint
	%if !WORD_SMALLTABLE && WORD_TABLE
		rset	NEXT_WORD, WORD_COUNT
	%endif
	%assign WORD_COUNT WORD_COUNT+1
%endmacro

%macro DEFFORTH 1
	DEF %1, no_next
	DOCOL
	%push defforth_ctx
%endmacro

%macro ENDDEF 0-1
	%if %0 == 0
	f_EXIT
	%endif
	%pop defforth_ctx
%endmacro

%macro WORD 1
	%if !WORD_TABLE && WORD_SIZE == 4
		WORD_DEF DEF%1
	%elif !WORD_TABLE && WORD_SIZE == 2
		WORD_DEF (DEF%1 - ASM_OFFSET + ELF_HEADER_SIZE)/WORD_ALIGN
	%elif !WORD_TABLE && WORD_SIZE == 1
		WORD_DEF (DEF%1 - ASM_OFFSET + ELF_HEADER_SIZE)/WORD_ALIGN
	%else
		%warning FOO4 WORD %1
		WORD_DEF %1
	%endif
%endmacro

%macro OVERRIDE_NEXT 1
	push n_%[%1]
	set FORTH_OFFSET, esp
%endmacro

%macro DIRECT_EXECUTE 1
	jmp short A_%[%1]
%endmacro

; execute 2 words. Undefined behaviour if the second word doesn't exit
; Second word has to be already defined.
; Second word is expected to be something like "exit"
%macro EXECUTE2 2
	OVERRIDE_NEXT	%2
	DIRECT_EXECUTE	%1
%endmacro

%macro DOCOL arg(0)
	DIRECT_EXECUTE DOCOL
	%%forth:
%endmacro

%imacro rspop arg(1)
	xchg	ebp, esp
	pop	%1
	xchg	ebp, esp
%endmacro

%imacro rspush arg(1)
	xchg	ebp, esp
	push	%1
	xchg	ebp, esp
%endmacro

%imacro lit 1
	%if %1 >= 0 && %1 < 256
		%warning FOO f_lit8 -- %1
		f_lit8
		%warning FOO2 f_lit8 -- %1
		db %1
	%else
		%warning FOO3 f_lit8 -- %1
		f_lit32
		dd %1
	%endif
%endmacro

%define offset(a)	(a - $$ + ELF_HEADER_SIZE)
%macro off2 1
	(%1 - $$ + ELF_HEADER_SIZE)
%endmacro

