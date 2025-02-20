; **** Macros ****

%macro NEXT arg(0)
	%if BIGJMP
		jmp    [edi]
	%else
		jmp short A_NEXT
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
	%if !WORD_SMALLTABLE && WORD_TABLE
		rset	NEXT_WORD, WORD_COUNT
	%endif
	%assign WORD_COUNT WORD_COUNT+1
%endmacro

%macro DEFFORTH 1
	%push defforth_ctx
	%$current:
	%if WORD_TABLE
		%assign wcurr	WORD_COUNT-1
	%else
		%define wcurr	(%$current - ASM_OFFSET + ELF_HEADER_SIZE)/WORD_ALIGN
	%endif

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
%else
	%define WORDVAL(a) (DEF%tok(a) - ASM_OFFSET + ELF_HEADER_SIZE)/WORD_ALIGN
%endif

%macro WORD 1
	WORD_DEF WORDVAL(%1)
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
		;%warning FOO f_lit8 -- %1
		f_lit8
		;%warning FOO2 f_lit8 -- %1
		db %1
	%else
		;%warning FOO3 f_lit8 -- %1
		f_lit32
		dd %1
	%endif
%endmacro

%define offset(a)	(a - $$ + ELF_HEADER_SIZE)
%macro off2 1
	(%1 - $$ + ELF_HEADER_SIZE)
%endmacro

