; **** Macros ****
%ifndef JMPLEN
%define JMPLEN short
%endif

%define roundup		WORD_ALIGN-1
%define offset(a)	(a - WORD_OFFSET + roundup)/WORD_ALIGN
%define offset_forth(a)	(a - FORTH_START + roundup)/WORD_ALIGN

%macro NEXT arg(0)
	jmp JMPLEN A_NEXT
%endmacro

%macro align2 2
	%ifidn %2,nop
		%assign a1 ($ - WORD_OFFSET) % %1
	%else
		%assign a1 ($ - FORTH_START) % %1
	%endif
	%if a1 != 0
		times (%1-a1) %2
	%endif
%endmacro

%macro f 1
	%if !DEBUG && ( %isidn(%1,"dbg") || %isidn(%1,"int3") )
		%warning "SKIP DEBUGWORD"
	%else
		%deftok %%A	%strcat("A_",%1))
		%if SCALED
			%assign %%val %tok(%strcat("q_",%1))
			%if %%val
				%assign %%off offset_forth(%%A) + LASTASM
			%else
				%assign %%off offset(%%A)
			%endif
			%if %%off > 255 && !%isdef(FORCE)
				%error word too big: wordname x
			%endif
			db	%%off
		%else
			dd	%%A
		%endif
	%endif
%endmacro

%macro assign_def 1
	%deftok %%A %strcat("A_",%1)
	%deftok %%v %strcat("v_",%1)
	%deftok %%Z %strcat("Z_",%1,"_",%str(xx))
	%deftok %$q %strcat("q_",%1)
	%%A:
	%define lastoff offset(%%A)
	%define lastoff2 %%A
	%if SPLIT
		%warning NEW DEFINITION: %1 WORD_COUNT
	%else
		%assign xx offset($)
		%%Z:
		%%v equ xx
		%warning NEW DEFINITION: %1 WORD_COUNT %eval(lastoff)
	%endif
	rtaint
	rset	eax, -2 ; 8-bit value
	%assign WORD_COUNT WORD_COUNT+1
%endmacro

%macro DEF 1
	%ifctx defcode
		%fatal Nested DEF not allowed. Did you forget an END?
	%endif
	%push defcode

	align2 WORD_ALIGN, nop
	assign_def %1
	%$q equ 0
%endmacro

%macro DEFFORTH 1
	%ifctx defforth
		%fatal Nested DEFFORTH not allowed. Did you forget an END?
	%endif
	%push defforth

	align2 WORD_ALIGN, db offset(A_nop)
	assign_def %1
	%$q equ 1
%endmacro

%macro endclearA 0.nolist
	%if haveclearA
		jmp	JMPLEN clearA
	%else
		%if A_needs_clearing
			%assign haveclearA 1
			clearA:
			A_tainted
		%endif
		%if !havenop && WORD_ALIGN > 1
			%assign havenop 1
			align2 WORD_ALIGN, nop
			A_nop:
			; XXX TODO: HACK
			%define DEF%[WORD_COUNT] A_nop
			%define f_nop WORD %[WORD_COUNT]
			%assign WORD_COUNT WORD_COUNT+1
		%endif

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
			f "EXIT"
		%endif
		%pop defforth
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
	%if CELL_SIZE == 4 && %isidn(RETURN_STACK,edi)
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
	mov	[embiggen(RETURN_STACK)], embiggen(%1)
%else
	xchg	RETURN_STACK, DATA_STACK
	push	%1
	xchg	RETURN_STACK, DATA_STACK
%endif
%endmacro
