; move TOS to B and push? Maybe in docol/next?
; popTOS
; pushTOS
; clearA


%ifdef C_EXIT
DEF "EXIT"
	mov     FORTH_OFFSET, [embiggen(RETURN_STACK)]
	END	no_next
%endif

%if %isdef(C_EXIT) || %isdef(C_rsdrop)
DEF "rsdrop"
	%if CELL_SIZE == 4 && %isidn(RETURN_STACK,edi)
		scasd
	%elif CELL_SIZE == 8 && %isidn(RETURN_STACK,edi)
		scasq
	%else
		lea     embiggen(RETURN_STACK), [embiggen(RETURN_STACK)+CELL_SIZE]
	%endif

	END
%endif


%ifdef C_dup
	DEF "dup"
		push	TOS
		END
%endif

; the minimal primitives
%ifdef C_store
	DEF "store"
		pop	native [TOS] ; I have to agree with Kragen here, I'm also amazed this is legal
		END	no_next
%endif
%if %isdef(C_store) || %isdef(C_drop)
	DEF "drop"
		END	popTOS
%endif

%ifdef C_fetch
	DEF "fetch"
		;push	native [TOS] ; This feels less illegal for some reason
		;END	popTOS
		mov	TOS, [TOS]
		END
%endif

%ifdef C_sp3
	DEF "sp3"
		push	SP
		END	no_next
%endif
%if %isdef(C_rpfetch) || %isdef(C_sp3)
	DEF "rpfetch"
		push	TOS
		; smaller because we use push, just to then end with popTOS,
		; instead of mov TO, RETURN_STACK
		push	RETURN_STACK
		END	popTOS
%endif

;%define C_droprpspfetch
%ifdef C_droprpspfetch
	DEF "droprpspfetch"
		push	RETURN_STACK
		push	SP
		END	popTOS
%endif

%ifdef C_rp3
	%define C_spfetch
%endif
%if %isdef(C_rpspfetch) && !%isdef(C_rp3)
	DEF "rpspfetch"
		push	TOS
		mov	TOS, RETURN_STACK
		END	no_next
%elifdef C_rp3
	DEF "rp3"
		push	RETURN_STACK
		END	no_next
%endif
%ifdef C_spfetch
	DEF "spfetch"
		push	TOS
		END	no_next
%endif
%if %isdef(C_spfetch) || %isdef(C_dropspfetch)
	DEF "dropspfetch"
		push	SP
		END	popTOS
%endif

%if !SYSCALL || %isdef(C_dupemit)
	DEF "dupemit"
		; this leaves the stack alone, so technically its a dup and emit combined
		assert_A_low
		rset	eax, -2
		taint	ebx, ecx, edx
		set	edx, 1
		set	eax, SYS_write
		set	ebx, 1
		push	TOS
		set	ecx, esp
		int	0x80
		pop	C
		; this will crash spectacularly if write was not successful (A != 1)
		A_tainted
		END
%endif
%if !SYSCALL || %isdef(C_bye)
DEF "bye"
	%if A_is_low
		mov	al, SYS_exit
	%else
		push	SYS_exit
		pop	A
	%endif
	mov	B, TOS
	int	0x80
	END	no_next
%endif


%if 0
	DEF "cstore"
		pop	C
		pop	D
		mov	[C], dl
		END

	DEF "cfetch"
		pop	D
		mov	al, [D]
		END

%endif

%ifdef C_rspush
	DEF "rspush"
		lea	RETURN_STACK, [embiggen(RETURN_STACK)-CELL_SIZE]
		pop	native [embiggen(RETURN_STACK)]
		END
%endif

%if SYSCALL64 && 0
DEF "emit64b"
	push	rdi
	push	rsi

	cdq
	inc	edx
	mov	eax, edx
	mov	edi, edx
	lea	rsi, [rsp+CELL_SIZE*2]

	syscall
	pop	rsi
	pop	rdi
	pop	rdx	; equivalent to drop
	END

DEF "emit32b"
	assert_A_low
	rset	eax, -2
	taint	ebx, ecx, edx
	set	edx, 1
	set	eax, SYS_write
	set	ebx, 1
	set	ecx, esp
	int	0x80
	pop	edx	; equivalent to drop
	END

%endif

%if COMBINED_STRINGOP
	%if %isdef(C_dotstr) || %isdef(C_string)
	; TODO document carry flag hack
	DEF "dotstr"
		clc
		END	no_next
	DEF "string"
		assert_A_low
		lodsb
		push	FORTH_OFFSET
		push	A
		lea	FORTH_OFFSET, [embiggen(FORTH_OFFSET)+A]
		jc	A_NEXT
		mov	al, offset(A_puts)
		jmp	xt
		END	no_next
	%endif
%else
	%ifdef C_dotstr
	DEF "dotstr"
		assert_A_low
		lodsb
		push	FORTH_OFFSET
		push	A
		add	FORTH_OFFSET, eax
		mov	al, offset(A_puts)
		jmp	xt
		END	no_next
	%endif
	%ifdef C_string
	DEF "string"
		assert_A_low
		lodsb
		push	FORTH_OFFSET
		add	FORTH_OFFSET, eax
		END	pushA
	%endif
%endif

%ifdef C_string0
DEF "string0"
	%if 0
		zero	A
		reg
		push	FORTH_OFFSET
		xchg	esi, edi
		reg
		repne	scasb
		xchg	esi, edi
		reg
	%else
		assert_A_low
		lodsb
		push	TOS
		mov	TOS, FORTH_OFFSET
		add	FORTH_OFFSET, eax
	%endif
	END
%endif

%ifdef C_stringr
DEF "stringr"
	assert_A_low
	lodsb
	push	A
	push	FORTH_OFFSET
	add	FORTH_OFFSET, eax
	END
%endif

%ifdef C_1minus
DEF "1minus"
	dec	TOS
	END
%endif

%ifdef C_1plus
DEF "1plus"
	inc	TOS
	END
%endif

%ifdef C_minus
DEF "minus"
	pop	C
	sub	aC, TOS
	xchg	aC, TOS
	END
%endif


%ifdef C_plus
DEF "plus"
	pop	C
	add	TOS, aC
	END
%endif

%if DEBUG
DEF "dbg"
	reg
	END
DEF "int3"
	int3
	END
%else
	%define f_dbg
	%define f_int3
%endif


;%define C_divmod
%ifdef C_divmod
DEF "divmod"
	assert_A_low
	cdq		; A is <= 255, so cdq will always work
	pop	A
	div	TOS
	mov	TOS, A
	xchg	A, D
	END	pushA
%endif

%ifdef C_nand
	DEF "nand"
		pop	D
		and	TOS, D
		END	no_next
%endif
%if %isdef(C_not) || %isdef(C_nand)
	DEF "not"
		not	TOS
		END
%endif

%ifdef C_nand2
	DEF "nand2"
		pop	A
		and	A, [esp]
		not	A
		END	pushA
%endif

%if 0
DEF "not2"
	;not	dword [esp]
	pop	eax
	not	eax
	END	pushA
DEF "and2"
	pop	ecx
	and	dword [esp],ecx
	END
%endif


%ifdef C_lt
DEF "lt"
	pop	D
	pop	A
	;cmp	C, D
	sub	A, D
	;setge	al
	cdq
	push	D
	END	clearA
%endif


%ifdef C_nzbranch
DEF "nzbranch"
	pop	C
	test	aC, aC
	jnz	A_branch
	incbr
	END	clearA
%endif

%ifdef C_zbranch
DEF "zbranch"
	mov	C, TOS
	; can't use END popTOS, because then tos wouldn't be popped if we branch
	pop	TOS
	jCz	A_branch
	
gobranch:
	incbr
	END
%endif

%if %isdef(C_branch) || %isdef(C_zbranch) || %isdef(C_zbranchc)
DEF "branch"
	%if BRANCH8
		movsx	ecx, byte [embiggen(FORTH_OFFSET)]
		add	FORTH_OFFSET, ecx
	%else
		mov	FORTH_OFFSET, [embiggen(FORTH_OFFSET)]
	%endif
	END
%endif


%ifdef C_0ne
DEF "0ne"
	neg	TOS
	sbb	TOS, TOS
	END

%endif

%ifdef C_0eq
DEF "0eq"
	test	TOS, TOS
	setnz	al
	dec	A
	xchg	A, TOS
	END	clearA
%endif



;%define C_0lt 1
%ifdef C_0lt
DEF "0lt"
	; from eForth. Would be 4 bytes smaller than my version
	; Unfortunately, it clashes with the A <= 255 condition of this
	; Forth, making it just 3 bytes smaller
	xchg	TOS, A
		END	no_next
%endif
%if %isdef(C_0lt) || %isdef(C_dropfalse)
DEF "dropfalse"
	cdq		; sign extend AX into DX
	push	D	; push 0 or -1
	END	popTOS

;DEF "0ee"
;	pop	A
;	neg	A
;	sbb	A, A
;	END	pushA
%endif

;%define C_2mul	1
%ifdef C_2mul
DEF "2mul"
	shl	TOS, 1
	END
%endif

%ifdef C_ror
DEF "ror"
	ror	TOS, 1
	END
%endif

%ifdef C_dup0lt
DEF "dup0lt"
	; from eForth. Would be 4 bytes smaller than my version
	; Unfortunately, it clashes with the A <= 255 condition of this
	; Forth, making it just 3 bytes smaller
	push	TOS
	xchg	A, TOS
	cdq		; sign extend AX into DX
	;push	D	; push 0 or -1
	xchg	A, TOS
	END
%endif

%ifdef C_varhelper
DEF "varhelper"
	push	esi
	jmp	A_EXIT
	END	no_next
%endif

%ifdef C_testasm
DEF "testasm"
	%if SCALED
		mov	al, v_testf
	%else
		mov	ax, A_testf
	%endif
	jmp	xt
	END	no_next
%endif

%ifdef C_rsinc
	DEF "rsinc"
		inc	native [RETURN_STACK]
		END
%endif

%ifdef C_rsinci
	DEF "rsinci"
		inc	native [RETURN_STACK]
		END	no_next
%endif
%if %isdef(C_rsinci) || %isdef(C_i)
	DEF "i"
		push	TOS
		push	native [RETURN_STACK]
		END	popTOS
%endif

%ifdef C_inext
DEF "inext"
	; XXX this one? ;dec	arith [embiggen(RETURN_STACK)]	; decrement loop counter
	dec	native [RETURN_STACK]
	jnz	A_branch

	%if CELL_SIZE == 4
		scasd
	%else
		scasq
	%endif

	jmp	gobranch
	END	no_next
%endif

%ifdef C_iloop
DEF "iloop"
	; XXX this one? ;dec	arith [embiggen(RETURN_STACK)]	; decrement loop counter
	inc	native [RETURN_STACK]
	mov	eax, [RETURN_STACK + CELL_SIZE]
	cmp	eax, [RETURN_STACK]
	jae	A_branch

	%if CELL_SIZE == 4
		scasd
	%else
		scasq
	%endif

	jmp	gobranch
	END	no_next
%endif

%ifdef C_emd
DEF "emd"
	assert_A_low
	lodsb
	push	eax
	mov	al, SYS_write
	set	ebx, 1
	set	ecx, esp
	set	edx, 1
	int	0x80
	END	clearA
%endif


%ifdef C_lit8
DEF "lit8"
	assert_A_low
	lodsb
	push	TOS
	push	A
	END	popTOS
%endif

%ifdef C_nzbranchc
DEF "nzbranchc"
	pop	C
	test	aC, aC
	jnz	A_branch
	incbr
	END	clearA
%endif

%ifdef C_zbranchc
DEF "zbranchc"
	pop	C
	jCz	A_branch
	
	END	no_next
%endif

%if %isdef(C_lit32) || %isdef(C_zbranchc)
DEF "lit32"
	lodsd
	push	TOS
	xchg	TOS, A
	END	clearA
%endif

%if BIT_ARITHMETIC == 64
DEF "lit64"
	lodsq
	END	pushA
%endif

%ifdef C_swap
DEF "swap"
	pop	C
	push	TOS
	push	C
	END	popTOS
%endif

%ifdef C_over
DEF "over"
	mov	A, [SP]
	push	TOS
	xchg	A, TOS
	END	clearA
%endif


%ifdef C_rot
DEF "rot"
	pop	D
	pop	C
	pop	A
	push	C
	END	pushDA
%endif

%ifdef C_syscall7
	DEF "syscall7"
		%ifidn RETURN_STACK,B
			%fatal invalid return stack register
		%endif
		pop	A
		pop	B
		pop	C
		pop	D
		; TODO: push/pop order all wrong
		%if 1
			pusha
			add	esp, 32
			pop	esi
			pop	edi
			pop	ebp
			int	0x80
			push	eax
			sub	esp, 32 + 8
			popa
			add	esp, 8
		%elif 1
			xchg	RETURN_STACK, DATA_STACK
			push	esi
			push	edi
			push	ebp
			xchg	RETURN_STACK, DATA_STACK
			pop	esi
			pop	edi
			pop	ebp
			int	0x80

			xchg	RETURN_STACK, DATA_STACK
			pop	edi
			pop	esi
			pop	ebp
			xchg	RETURN_STACK, DATA_STACK
		%else
			push	esi
			mov	esi, [esp+4]
			push	edi
			mov	edi, [esp+12]
			push	ebp
			mov	ebp, [esp+20]

			int	0x80
			pop	ebp
			pop	edi
			pop	esi

			pop	edx
			pop	edx
			pop	edx
		%endif

		END	pushA
%endif


%ifdef C_syscall3_noret
%if !SYSCALL64
	DEF "syscall3_noret"
		%ifidn RETURN_STACK,B
			%fatal invalid return stack register
		%endif
		xchg	A, TOS
		pop	B
		pop	C
		pop	D

		int	0x80
		END	popTOS
%else
	DEF "syscall3_noret"
		%ifidn RETURN_STACK,DI
			%fatal invalid return stack register
		%endif
		mov	SYSCALL_SAVE, FORTH_OFFSET

		xchg	A, TOS
		pop	DI
		pop	SI
		pop	D

		syscall
		mov	FORTH_OFFSET, SYSCALL_SAVE
		END	popTOS
%endif
%endif

%ifdef C_syscall3
%if !SYSCALL64
	DEF "syscall3"
		%ifidn RETURN_STACK,B
			%fatal invalid return stack register
		%endif
		xchg	A, TOS
		pop	B
		pop	C
		pop	D

		int	0x80
		xchg	A, TOS
		END	clearA
%else
; x64 syscall: syscall number in rax
; params: rdi, rsi, rdx, r10, r8 , r9
; para32: ebx, ecx, edx, esi, edi, ebp
; num...: 1    2    3    5    6    7
; clobbered: rax, rcx, r11
; we got to save rdi and rsi
; free: rbx, rbp(?), r12, r13, r14, r15
DEF "syscall3"
	%ifidn RETURN_STACK,DI
		%fatal invalid return stack register
	%endif
	mov	SYSCALL_SAVE, FORTH_OFFSET

	xchg	A, TOS
	pop	DI
	pop	SI
	pop	D

	syscall
	mov	FORTH_OFFSET, SYSCALL_SAVE
	push	A
	END	popTOS
%endif

%endif
