%if 0
. ./viert.sh
%endif

; Bitness flags:
; BIT: 32 or 64. What kind of code is being executed
; X32: true if we are compiling an "x32" binary - 64-bit code with 32-bit pointers.
; FORCE_ARITHMETIC_32: use 32-bit arithmetic instructions when running 64-bit code
; B64: flag for regdump

BITS BIT

;%define B64

%define REG_OPT		1
%define REG_SEARCH	1
%define REG_ASSERT	0

%include "stdlib.mac"

; use scaled, relative offsets
%ifndef SCALED
%define SCALED		1
%endif

; Which literal function to use for 32bit literals
%ifndef LIT
%define LIT		xlit32
%endif

; smaller init code.
%ifndef SMALLINIT
%define SMALLINIT	3
%endif

; make our memory writable. Needed for variables. Not working together with SMALLINIT atm
%ifndef RWMEM
%define RWMEM		0
%endif

; branching with 8 bit values. Bigger asm part because of movsx, probably smaller overall
%ifndef BRANCH8
%define BRANCH8		0
%endif

; implement (conditional) branches in pure forth with 0< rp@ @ !
%ifndef FORTHBRANCH
%define FORTHBRANCH	0
%endif

; enable syscall words. If 0, emit/exit will use hardcoded syscalls
%ifndef SYSCALL
%define SYSCALL		1
%endif

; full ELF file. Version with FULL=0 won't have debug info/won't load in gdb at all
%ifndef FULL
%define FULL		0
%endif

; force 32-bit arithmetic, even when compiling for 64-bit systems
%ifndef FORCE_ARITHMETIC_32
%define FORCE_ARITHMETIC_32 0
%endif

%if	(BIT == 64 && !FORCE_ARITHMETIC_32)
	%define BIT_ARITHMETIC	64
%else
	%define BIT_ARITHMETIC	32
%endif

%if BRANCH8
	%macro dbr 1
		%warning BRANCH8 %1
		db %1 - $
	%endmacro
	%define incbr	lodsb
%else
	%if FORTHBRANCH
		%macro dbr 1
			%warning FORTHBRANCH %1
			;dd %1 - $	; relative
			dd %1		; absolute
		%endmacro
	%else
		%macro dbr 1
			%warning BRANCH32 %1
			dd %1
		%endmacro
	%endif
	%define incbr	lodsd
%endif

; WHILE in pure forth
%ifndef FORTHWHILE
%define FORTHWHILE	0
%endif

; dotstr and string mixed:
%ifndef COMBINED_STRINGOP
%define COMBINED_STRINGOP 0
%endif

; Position independent code
%ifndef PIC
%define PIC		0
%endif


%ifndef HARDEN
%define HARDEN		0
%endif

%ifndef X32
%define X32		0
%endif

%ifndef SYSCALL64
	%if BIT == 64 && !X32
		%define SYSCALL64	1
	%else
		%define SYSCALL64	0
	%endif
%endif

%if BIT == 64
	%define	A		rax
	%define	B		rbx
	%define	C		rcx
	%define	D		rdx
	%define	BP		rbp
	%define	SP		rsp
	%define	DI		rdi
	%define	SI		rsi
	%define	jCz		jrcxz
	%define	native		qword
	%define	CELL_SIZE	8
%else
	%define	A		eax
	%define	B		ebx
	%define	C		ecx
	%define	D		edx
	%define	BP		ebp
	%define	SP		esp
	%define	DI		edi
	%define	SI		esi
	%define	jCz		jecxz
	%define	native		dword
	%define	CELL_SIZE	4
%endif

; those two are pretty much fixed, due to push/pop and lods*
%define	DATA_STACK	SP
%define	FORTH_OFFSET	esi

%if SYSCALL64
	; A: used by syscall, lodsb
	; B: unused
	; C: used by jCz, divmod(?) and rot(?)
	; D: used by syscall, 0lt(?)
	; SP: used by DATA_STACK
	; SI: used by syscall, FORTH_OFFSET
	; DI: used by syscall
	; BP: unused
	; RETURN_STACK:	not DATA_STACK, FORTH_OFFSET, A, C, D, DI, SI, R11
	; leaves us with B, BP, R12-R15. BP and R12-R15 have additional encoding overhead
	%define	RETURN_STACK	B
	; TEMP_ADDR:	not RETURN_STACK, DATA_STACK, FORTH_OFFSET, A
	; leaves us with B, C, D, DI, BP, R12-R15. BP and R12-R15 have additional encoding overhead
	%define	TEMP_ADDR	edi
	; SYSCALL_SAVE:	not RETURN_STACK, DATA_STACK, FORTH_OFFSET, A, C, D, DI, SI, R11 
	; leaves us with B, BP, R12-R15. R12-R15 have additional encoding overhead
	%define	SYSCALL_SAVE	ebp	; FORTH_OFFSET will get saved here during syscalls
	%define SYS_write	1
	%define SYS_exit	60
%else
	; A: used by syscall, lodsb
	; B: used by syscall
	; C: used by syscall, jCz, divmod(?) and rot(?)
	; D: used by syscall, 0lt(?)
	; SP: used by DATA_STACK
	; SI: used by FORTH_OFFSET
	; DI: unused
	; BP: unused
	; RETURN_STACK:	not DATA_STACK, FORTH_OFFSET, A, B, C, D
	; leaves us with DI, BP. BP has additional encoding overhead
	%define	RETURN_STACK	DI
	; TEMP_ADDR:	not RETURN_STACK, DATA_STACK, FORTH_OFFSET, A
	; leaves us with B, C, D, DI, BP. BP has additional encoding overhead
	%define	TEMP_ADDR	ecx
%endif

%if X32
	%xdefine	DATA_STACK	emsmallen(DATA_STACK)
	%xdefine	RETURN_STACK	emsmallen(RETURN_STACK)
%endif

%if 0 && PIC ; 64 bit PIC support currentl broken - needs some more refactoring
	%define	FORTH_OFFSET	rsi
	%define	TEMP_ADDR	rdi
%endif

%assign	WORD_COUNT	0
%define zero_seg	0

%ifndef WORD_ALIGN
%define WORD_ALIGN	2
%endif

%if !SCALED
	%assign WORD_ALIGN	1	; no scaling, so always 1
	%define	TEMP_ADDR	eax	; no separate register to do offset/scaling
%endif

%if %isidn(LIT,lit32)
	%assign C_lit32 1
%endif

%ifndef WORD_SIZE
%define WORD_SIZE	0
%endif

%assign BITM1		BIT - 1

; 52 byte for ELF header, 32 byte for each program header
%define elf_extra_align 0
%if WORD_ALIGN == 8
	%define elf_extra_align 4
%endif
%define ELF_HEADER_SIZE (52 + 1*32 + elf_extra_align)

%if PIC
	%define BASE ebp
%else
	%define BASE WORD_OFFSET
%endif

; **** Macros ****
%include "macros.asm"

; **** Codeword definitions ****
SECTION .text align=1

%if !FULL
	%define ELF_OFFSET 0x20
	org ORG
	ELF
%else
	_start:
%endif


A_INIT:
rdump

%if SMALLINIT == 1
	;%ifnidn embiggen(RETURN_STACK),BP
	dec	cx
	inc	ecx
	mov	RETURN_STACK, SP
	;alloca	128
	sub	SP, C
	;add	C, byte (FORTH - 0xffff)
	mov	cl, FORTH - 0x10000

	ELF_PHDR 1
%elif SMALLINIT == 3
	mov	TEMP_ADDR, FORTH
	mov	RETURN_STACK, SP
	sub	SP, TEMP_ADDR

	ELF_PHDR 1
%else
; "enter" will push ebp on the stack
; This means that we can call EXIT to start the forth code at ebp
; And conveniently, EXIT is the first defined word, so we can "call" it
; by simply doing nothing
	enter	0xFFFF, 0
	%ifnidn embiggen(RETURN_STACK),BP
		%if X32
			xchg	RETURN_STACK,ebp
		%else
			xchg	RETURN_STACK,BP
		%endif
	%endif
	%if PIC
		ELF_PHDR 1
		%if BIT == 64
			lea	TEMP_ADDR, [rel FORTH]
		%else
			call	.below
		.below:	pop	BASE
			add	BASE, (WORD_OFFSET-.below)
		%endif
		lea	TEMP_ADDR, [BASE + (FORTH-WORD_OFFSET)]
	%else
		rinit
		%if SMALLINIT != 2
			%if RWMEM && ELF_CUSTOM
				%ifdef ORG
					set	ebx, ORG
				%else
					set	ecx, 0xffff
				%endif
			%endif
			ELF_PHDR 1
			%if RWMEM && ELF_CUSTOM
				_rwx:
				taint	RETURN_STACK
				rwx
			%endif
			; we chose our base address to be < 2^32. So no embiggen
			mov	TEMP_ADDR, FORTH
		%else
			mov	al, offset(FORTH)
			ELF_PHDR 1
			jmp	xt
		%endif
	%endif
%endif

%include "codewords.asm"

; IMMEDIATE WORDS
; TODO: handle better

%macro string 1
	f_string
	db %%endstring - $ - 1
	db %1
	%%endstring:
%endmacro

%macro stringr 1
	f_stringr
	db %%endstring - $ - 1
	db %1
	%%endstring:
%endmacro

%macro string0 1
	f_string0
	db %%endstring - $ - 1
	db %1, 0
	%%endstring:
%endmacro

%macro print 1
	stringr %1
	lit 1
	lit 4
	f_syscall3_noret
%endmacro

%macro dotstr 1
	f_dotstr
	db %%endstring - $ - 1
	db %1
	%%endstring:
%endmacro

;%macro inline_asm 0
;	%push asmctx
;	f_string
;	db %$endasm - $ - 1
;	%$asm:
;%endmacro
;
;%macro endasm 0
;	NEXT
;	%$endasm:
;	f_asmjmp
;	%pop asmctx
;%endmacro
;
;%macro until arg(0)
;	f_zbranch
;	dbr %$dountil
;	%pop dountilctx
;%endmacro

%macro zbranch arg(1)
	%if FORTHBRANCH
		f_xzbranch
		dbr %1
	%elifdef f_zbranch
		f_zbranch
		dbr %1
	%else
		f_zbranchc
		dbr %1
		f_drop
	%endif
%endmacro

%macro branch arg(1)
	%if FORTHBRANCH
		f_xbranch
		dbr %1
	%else
		f_branch
		dbr %1
	%endif
%endmacro


;%macro while arg(0)
;	f_not
;	zbranch %$dountil
;	%pop dountilctx
;%endmacro

%macro unless arg(0)
	%ifdef f_nzbranch
		%push ifctx
		f_nzbranch
		dbr %$jump1
	%else
		if
		else
	%endif
%endmacro

%macro if arg(0)
	%if %isdef(f_zbranch) || %isdef(f_zbranchc) || %isdef(f_xzbranch)
		%push ifctx
		zbranch %$jump1
	%else
		unless
		else
	%endif
%endmacro

%macro then arg(0)
	%$jump1:
	%ifctx elsectx
		;%error ELSECTX
		%pop elsectx
		%ifctx elsectx
			%error "nested else - did you try unless .. else .. then without activating nzbranch?"
		%endif
	%endif
	%pop ifctx
%endmacro
%defalias endif then

%macro else arg(0)
	%push elsectx
	branch %$jump1

	%$$jump1:
%endmacro

%macro do arg(0)
	%push doctx
	f_swap
	f_rspush
	f_rspush
	%$dolabel:
%endmacro

%macro swapdo arg(0)
	%push doctx
	f_rspush
	f_rspush
	%$dolabel:
%endmacro

%macro loop arg(0)
	%ifnctx doctx
		%fatal not doctx
	%endif
	%ifdef f_j
		%$j:	f_j
	%else
		%ifdef f_rpfetch
			f_rpfetch
		%else
			f_rpspfetch
			f_drop
		%endif
		%$lit:	lit CELL_SIZE
		%$plu:	f_plus
		%$fetc:	f_fetch
	%endif
	%$rsin:	f_rsinci
	%$minu:	f_minus
	%$if:	if
	%$bran:	jump %$$dolabel
		then
		%pop doctx
%endmacro

%macro loople arg(0)
%ifdef f_iloop
	f_iloop
	dbr %$dolabel
%else
	%ifnctx doctx
		%fatal not doctx
	%endif
	%$rsin:	f_rsinci
	%ifdef f_j
		%$j:	f_j
	%else
		%ifdef f_rpfetch
			f_rpfetch
		%else
			f_rpspfetch
			f_drop
		%endif
		%$lit:	lit CELL_SIZE
		%$plu:	f_plus
		%$fetc:	f_fetch
	%endif
	%$minu:	f_not
		f_plus
	%$if:	if
	%$bran:	jump %$$dolabel
		then
%endif
		%pop doctx
%endmacro



%macro begin 0
	%push beginloop
	%$loop:
%endmacro

%macro again 0
	branch %$loop
	%$end:
	%pop beginloop
%endmacro

%macro f_leave 0
	%ifctx beginloop
		branch %$end
	%elifctx ifctx
		branch %$$end
	%elifctx elsectx
		branch %$$$end
	%else
		%error "unknown context for leave"
	%endif
%endmacro

%macro until 0
	%if %isdef(f_zbranch) || %isdef(f_zbranchc)
		%$zbr: zbranch %$loop
		%pop beginloop
	%else
		%$not: f_not
		%$notuntil: notuntil
	%endif

%endmacro

%macro notuntil 0
	%ifdef f_nzbranch
		%$nzbr: f_nzbranch
		dbr %$loop
		%pop beginloop
	%else
		%$not0: f_not
		%$until: until
	%endif

%endmacro

%macro for 0
	f_rspush
	%push forloop
	%$forloop:
%endmacro

%macro f_xi 0
	%ifdef C_rpfetch
		f_rpfetch
	%else
		f_rpspfetch
		f_drop
	%endif
	f_fetch
%endmacro

%macro next 0
%ifdef	C_inext
	f_inext
	dbr %$forloop
%else
	%$i:	f_i
	%$dec:	f_dec
	%$dup:	f_dup
	%$rpfe:	f_rpfetch
	%$stor:	f_store

	%if 1
		if
			branch %$$forloop
		then
	%else
		f_zbranch
		dbr %$else
		branch %$forloop
		%$else:
	%endif
	f_rsdrop
%endif
%pop forloop
%endmacro

FORTH_START:
%include "compiled.asm"

%if ELF_CUSTOM
	%assign HEADER 0
%else
	%assign HEADER 84
%endif
%if SMALLINIT == 2
	%assign x offset(FORTH)
	%if x > 255
		%error x too big for smallinit == 2
	%endif
%endif

%if SMALLINIT == 1 && (FORTH - $$ + HEADER) > 0xff
	%warning SMALLINIT: %eval(FORTH - $$ + HEADER) > 255
	%ifdef FORCE
		%warning "too much code for SMALLINIT"
	%else
		%error   "too much code for SMALLINIT"
	%endif
%endif
A_END:
%if DEBUG
	; after A_END, because we don't want to count it towards the total
	int3
	A_regdump:
	%include "regdump2.mac"
%endif

%assign FORTH_WORDS WORD_COUNT - ASM_WORDS
%define FORTH_SIZE %eval(lastoff2 - FORTH_START)
%warning "ASM_SIZE" ASM_SIZE
%warning "ASM_WORDS" ASM_WORDS
%if ASM_WORDS > 0
	%warning "ASM_RATIO" %eval(ASM_SIZE/ASM_WORDS)
%endif
%warning "FORTH_SIZE" FORTH_SIZE
%warning "FORTH_WORDS" FORTH_WORDS
%if FORTH_WORDS > 0
	%warning "FORTH_RATIO" %eval(FORTH_SIZE/FORTH_WORDS)
%endif
%warning "WORDS TOTAL" WORD_COUNT
%warning "BREAK" %eval(BREAK)
%ifdef lastoff
	%warning "LASTOFF" %eval(lastoff)
%endif
%warning "LASTOFF2" %eval((lastoff2 - $$)/WORD_ALIGN)
