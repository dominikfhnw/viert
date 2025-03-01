; **** Macros ****
%ifndef JMPLEN
%define JMPLEN short
%endif

%if OFFALIGN
	%define offset(a)	(a - ASM_OFFSET + ELF_HEADER_SIZE)/WORD_ALIGN
%else
	%define offset(a)	(a - ASM_OFFSET)/WORD_ALIGN
%endif

%macro NEXT arg(0)
	%if BIGJMP
		jmp    [BASE]
	%else
		jmp JMPLEN A_NEXT
	%endif
%endmacro

%macro DEF 1-2.nolist
	%if %0 == 1
		NEXT
	%endif
	align WORD_ALIGN, nop
	; objdump prints the lexicographical smallest label. change A to E
	; or something to get the DEFn labels
	;DEF%[WORD_COUNT]:
	%define DEF%[WORD_COUNT] A_%tok(%1)
	A_%tok(%1):
	%define %[n_%tok(%1)] %[WORD_COUNT]
	%define %[f_%tok(%1)] WORD %[WORD_COUNT]
	%warning NEW DEFINITION: DEF%[WORD_COUNT] %1
	;%define %[%tok(%1)] WORD %[WORD_COUNT]
	rtaint
	;%if !WORD_SMALLTABLE && WORD_TABLE
		rset	NEXT_WORD, WORD_COUNT
	;%endif
	%assign WORD_COUNT WORD_COUNT+1
%endmacro

%macro DEFFORTH 1
	%ifctx defforth_ctx
		%fatal Nested DEFFORTH not allowed. Did you forget an ENDDEF?
	%endif
	%push defforth_ctx
	%$current:
	%if WORD_TABLE
		%assign wcurr	WORD_COUNT-1
	%else
		%define wcurr	offset(%$current)
	%endif

	; another align here, to override "align with nop"
	align WORD_ALIGN, db 0
	DEF %1, no_next
	%if !THRESH
		DOCOL
	%endif
%endmacro

%macro	RECURSE 0
	WORD_DEF wcurr
%endmacro

%macro ENDDEF 0-1
	%if %0 == 0
	f_EXIT
	%endif
	%pop defforth_ctx
%endmacro

%if WORD_TABLE
	%define WORDVAL(a) a
%elif WORD_SIZE == 4
	%define WORDVAL(a) DEF%tok(a)
%else
	%define WORDVAL(a) offset(DEF%tok(a))
%endif

%macro WORD 1
	WORD_DEF WORDVAL(%1)
%endmacro

; XXX unused?
%macro OVERRIDE_NEXT 1
	push n_%[%1]
	set FORTH_OFFSET, esp
%endmacro

%macro DIRECT_EXECUTE 1
	jmp A_%[%1]
%endmacro

; execute 2 words. Undefined behaviour if the second word doesn't exit
; Second word has to be already defined.
; Second word is expected to be something like "exit"
; XXX unused?
%macro EXECUTE2 2
	OVERRIDE_NEXT	%2
	DIRECT_EXECUTE	%1
%endmacro

%macro DOCOL arg(0)
	DIRECT_EXECUTE DOCOL
	%%forth:
%endmacro

%imacro rspop arg(1)
	xchg	RETURN_STACK, esp
	pop	%1
	xchg	RETURN_STACK, esp
%endmacro

%imacro rspush arg(1)
%if 0
	lea	RETURN_STACK, [RETURN_STACK-4]
	mov	[RETURN_STACK], FORTH_OFFSET
%else
	xchg	RETURN_STACK, esp
	push	%1
	xchg	RETURN_STACK, esp
%endif
%endmacro

%imacro lit 1
	%if (%1 >= 0 && %1 < 256)
		f_lit8
		db %1
	%else
		f_lit32
		dd %1
	%endif
%endmacro
