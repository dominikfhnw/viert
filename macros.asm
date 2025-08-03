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

%macro align2 2
	%assign a1 ($ - WORD_OFFSET) % %1
	%if a1 != 0
		times (%1-a1) %2
	%endif
%endmacro

%macro DEF 1-2.nolist
	%ifctx defcode
		%fatal Nested DEF not allowed. Did you forget an ENDDEF?
	%endif
	%push defcode

	align2 WORD_ALIGN, nop
	%define DEF%[WORD_COUNT] A_%tok(%1)
	A_%tok(%1):
	%define %[f_%tok(%1)] WORD %[WORD_COUNT]
	%define lastoff offset(A_%tok(%1))
	%define lastoff2 A_%tok(%1)
	%warning NEW DEFINITION: %1 WORD_COUNT %eval(lastoff)
	rtaint
	rset	eax, -2 ; 8-bit value
	%assign WORD_COUNT WORD_COUNT+1
%endmacro

%macro DEFFORTH 1
	%ifctx defforth
		%fatal Nested DEFFORTH not allowed. Did you forget an ENDDEF?
	%endif

	; another align here, to override "align with nop"
	align2 WORD_ALIGN, db offset(A_nop)
	DEF %1, no_next
	%repl defforth
%endmacro

%macro END 0-1.nolist
	%ifctx defcode
		%if %0 == 0
			NEXT
		%elif %1 == clearA
			jmp short clearA
		%elif %1 == pushA
			jmp short pushA
		%elif %1 == pushDA
			jmp short pushDA
		%elif %1 == no_next
			; nothing
		%else
			%error unknown statement after END: %1
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

%macro WORD 1
	db offset(DEF%tok(%1))
%endmacro

; "A noble spirit embiggens the smallest man."
%if BIT == 32
	%define embiggen(a)  a
%else
	%define embiggen(a)  %tok(%strcat("r",%substr(a,2,2)))
%endif

%define emsmallen(a)  %tok(%strcat("e",%substr(a,2,2)))

%macro embiggen_conditional arg(1)
	%if BIT == 64
		%substr reg_prefix %str(%1) 1,1
		%ifidn reg_prefix,'e'
			%define out embiggen(%1)
		%else
			%define out %1
		%endif
	%else
		%define out %1
	%endif
%endmacro


%macro pop arg(1)
	%if BIT == 64
		embiggen_conditional %1
		%warning POPWRAP %1 -> out
		pop out
	%else
		pop %1
	%endif
%endmacro

%macro push arg(1)
	%if BIT == 64
		embiggen_conditional %1
		push out
	%else
		push %1
	%endif
%endmacro

%imacro rspop arg(1)
%if 1
	mov	%1, [embiggen(RETURN_STACK)]
	%if CELL_SIZE == 4
		scasd
	%else
		lea     RETURN_STACK, [embiggen(RETURN_STACK)+CELL_SIZE]
	%endif
%else
	xchg	RETURN_STACK, DATA_STACK
	pop	%1
	xchg	RETURN_STACK, DATA_STACK
%endif
%endmacro

%imacro rspush arg(1)
%if 1
	lea	RETURN_STACK, [embiggen(RETURN_STACK)-CELL_SIZE]
	mov	[embiggen(RETURN_STACK)], %1
%else
	xchg	RETURN_STACK, DATA_STACK
	push	%1
	xchg	RETURN_STACK, DATA_STACK
%endif
%endmacro

%imacro lit 1
	%if LIT8 && (%1 >= 0 && %1 < 256)
		f_lit8
		db %1
	; TODO: this won't work with large negative numbers
	%elif (BIT_ARITHMETIC == 64) && (%1 > 0xffffffff)
		f_lit64
		dq %1
	%else
		f_lit32
		dd %1
	%endif
%endmacro
