; **** Macros ****
%ifndef JMPLEN
%define JMPLEN short
%endif

%if OFFALIGN
	%define offset(a)	(a - WORD_OFFSET + ELF_HEADER_SIZE)/WORD_ALIGN
%else
	%define offset(a)	(a - WORD_OFFSET)/WORD_ALIGN
%endif

%macro NEXT arg(0)
	jmp JMPLEN A_NEXT
%endmacro

%macro DEF 1-2.nolist
	%ifctx defcode
		%fatal Nested DEF not allowed. Did you forget an ENDDEF?
	%endif
	%push defcode

	align WORD_ALIGN, nop
	%define DEF%[WORD_COUNT] A_%tok(%1)
	A_%tok(%1):
	%define %[n_%tok(%1)] %[WORD_COUNT]
	%define %[f_%tok(%1)] WORD %[WORD_COUNT]
	%warning NEW DEFINITION: DEF%[WORD_COUNT] %1
	rtaint
	rset	NEXT_WORD, -2 ; 8-bit value
	%assign WORD_COUNT WORD_COUNT+1
%endmacro

%macro DEFFORTH 1
	%ifctx defforth
		%fatal Nested DEFFORTH not allowed. Did you forget an ENDDEF?
	%endif

	; another align here, to override "align with nop"
	align WORD_ALIGN, db 0
	DEF %1, no_next
	%repl defforth
%endmacro

%macro END 0-1
	%ifctx defcode
		%if %0 == 0
			NEXT
		%endif
		%pop defcode
	%else
		%if %0 == 0
			f_EXIT
		%endif
		%pop defforth
	%endif
%endmacro
%define ENDDEF END

%define WORDVAL(a) offset(DEF%tok(a))

%macro WORD 1
	WORD_DEF WORDVAL(%1)
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
	%if LIT8 && (%1 >= 0 && %1 < 256)
		f_lit8
		db %1
	%else
		f_lit32
		dd %1
	%endif
%endmacro
