; **** Macros ****
%ifndef JMPLEN
%define JMPLEN short
%endif

%define offset(a)	(a - WORD_OFFSET)/WORD_ALIGN

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
		%fatal Nested DEF not allowed. Did you forget an END?
	%endif
	%push defcode

	align2 WORD_ALIGN, nop
	%define DEF%[WORD_COUNT] A_%tok(%1)
	A_%tok(%1):
	%assign xx ($ - WORD_OFFSET)/WORD_ALIGN
	Z_%tok(%1)_%[xx]:
	%define %[f_%tok(%1)] WORD %[WORD_COUNT]
	%[v_%tok(%1)] equ xx
	%define lastoff offset(A_%tok(%1))
	%define lastoff2 A_%tok(%1)
	%define f_recurse %[f_%tok(%1)] 
	%warning NEW DEFINITION: %1 WORD_COUNT %eval(lastoff)
	rtaint
	rset	eax, -2 ; 8-bit value
	%assign WORD_COUNT WORD_COUNT+1
%endmacro

%macro DEFFORTH 1.nolist
	%ifctx defforth
		%fatal Nested DEFFORTH not allowed. Did you forget an END?
	%endif

	; another align here, to override "align with nop"
	align2 WORD_ALIGN, db offset(A_nop)
	DEF %1, no_next
	%repl defforth
%endmacro

%macro endclearA 0.nolist
	%if !A_needs_clearing
		NEXT
	%elif haveclearA
		jmp	JMPLEN clearA
	%else
		%assign haveclearA 1
		clearA:
		A_tainted
		NEXT
	%endif
%endmacro

%macro endpushA 0.nolist
	%if havepushA
		jmp	JMPLEN pushA
	%else
		%assign havepushA 1
		pushA:
		push	A
		endclearA
	%endif
%endmacro

%macro endpushDA 0.nolist
	%if havepushDA
		jmp	JMPLEN pushDA
	%else
		%assign havepushDA 1
		pushDA:
		push	D
		endpushA
	%endif
%endmacro

%macro endpopTOS 0.nolist
	%if havepopTOS
		jmp	JMPLEN popTOS
	%else
		%assign havepopTOS 1

		;A_popTOS:
		;; XXX TODO: HACK
		;%define DEF%[WORD_COUNT] A_popTOS
		;%define f_popTOS WORD %[WORD_COUNT]
		;%assign WORD_COUNT WORD_COUNT+1

		popTOS:
		pop	TOS
		endclearA
	%endif
%endmacro

%macro endcode 1.nolist
	%ifidn %1,clearA
		endclearA
	%elifidn %1,pushA
		endpushA
	%elifidn %1,pushDA
		endpushDA
	%elifidn %1,popTOS
		endpopTOS
	%else
		%error unknown statement after END: %1
	%endif
%endmacro

%macro END 0-1.nolist
	%ifctx defcode
		%if %0 == 0
			NEXT
		%elifidn %1,no_next
			; nothing
		%else
			endcode %1
		%endif
		%pop defcode
	%else
		%if %0 == 0
			f_EXIT
		%endif
		%pop defforth
	%endif
%endmacro

%macro WORD 1
	%if SCALED
		%assign x %eval(offset(DEF%tok(%1)))
		%xdefine wordname DEF%tok(%1)
		%if x > 255
			%ifndef FORCE
				%error word too big: wordname x
			%endif
		%endif
		db offset(wordname)
	%else
		dd DEF%tok(%1)
	%endif

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

%imacro xlit32 1.nolist
	f_xlit32
	dd %1
%endmacro

%imacro lit 1.nolist
%if 0
        %defstr %%n %1
        %ifnum %1
                %warning %?: %%n %eval(%1) is number %%id
        %elifstr %1
                %warning %?: %%n %eval(%1) is str/true %%id
        %elifempty %1
                %warning %?: %%n is empty %%id
        %eliftoken %1
                %ifid %1
                        %warning %?: %%n is token %%id
                %else
                        %warning %?: %%n is token/notid %%id
                %endif
        %elifid %1
                %warning %?: %%n is id %%id
        %else
                %warning %?: %%n is UNKNOWN %%id
        %endif
%endif
	;%if ( %isnum(%1) || %isstr(%1) ) && %isdef(C_lit8) && (%1 >= 0 && %1 < 256)
	;%if ( ! %isid(%1) ) && %isdef(C_lit8) && (%1 >= 0 && %1 < 256)
	%if %isdef(C_lit8) && ( %isnum(%1) || %isstr(%1) )
		%if %1 >= 0 && %1 < 256
			f_lit8
			db %1
		%else
			f_%[LIT]
			dd %1
		%endif
	; TODO: this won't work with large negative numbers
	%elif (BIT_ARITHMETIC == 64) && (%1 > 0xffffffff)
		f_lit64
		dq %1
	%else
		f_%[LIT]
		dd %1
	%endif
%endmacro
