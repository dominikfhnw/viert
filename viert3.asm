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

%if FORTHBRANCH
	%macro dbr 1
		%warning FORTHBRANCH %1
		;dd %1 - $	; relative
		dd %1		; absolute
	%endmacro
	%define incbr
%elif BRANCH8
	%macro dbr 1
		%warning BRANCH8 %1
		db %1 - $
	%endmacro
	%define incbr	lodsb
%else
	%macro dbr 1
		%warning BRANCH32 %1
		dd %1
	%endmacro
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

%ifdef WORDSET
	%include "oldwordset.asm"
%else
	%include "wordset.asm"
%endif

%ifdef C_EXIT
	%define C_DOCOL
	%define INIT_REG TEMP_ADDR
%else
	%define INIT_REG FORTH_OFFSET
%endif


%if SMALLINIT == 1
	;;%ifnidn embiggen(RETURN_STACK),BP
	;dec	cx
	;inc	ecx
	;mov	RETURN_STACK, SP
	;;alloca	128
	;sub	SP, C
	;;add	C, byte (FORTH - 0xffff)
	;mov	cl, FORTH - 0x10000

	;ELF_PHDR 1
%elif SMALLINIT == 3
	mov	INIT_REG, FORTH
	mov	RETURN_STACK, SP
	sub	SP, INIT_REG

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

;;; OLD CODEWORDS.ASM
%define BREAK offset(END_OF_CODEWORDS-2)

%assign A_is_low 0
; clear A/eax either in words or the inner interpreter
; Nb: xor eax, eax also clears upper 32bits on 64bit
%if SCALED
	%define assert_A_low
	%define A_tainted	xor eax, eax
; no need to clear A in most cases in non-scaled mode
%else
	%define assert_A_low	xor eax, eax
	%define A_tainted
%endif

; ENTER - set up stack frame for function
;       - push EBP on stack, move esp to ebp, subtracct imm from esp
;push	ebp
;mov	ebp, esp
;sub	esp, imm

; LEAVE - Set ESP to EBP, then pop EBP.
;mov	esp, ebp
;pop	ebp

%ifdef C_DOCOL
A_DOCOL:
rspush	FORTH_OFFSET
xchg	FORTH_OFFSET, TEMP_ADDR
%if DEBUG	; turn on to inspect return stack in GDB with "b INSP"
DEBUGCOL:
	xchg	SP, RETURN_STACK
	BP2:
	INSP:
	xchg	SP, RETURN_STACK
%endif
%endif

A_NEXT:
%if SCALED
	assert_A_low
	lodsb
	%assign A_is_low 1 ; flag to indicate A is low when words are called
	xt:
	lea	TEMP_ADDR, [A*WORD_ALIGN+BASE]
	;cmp	eax, BREAK
	%ifdef C_DOCOL
		cmp	al, BREAK
	%endif
	;cmp	TEMP_ADDR, END_OF_CODEWORDS-2
%else
	lodsd
	xt:
	%ifdef C_DOCOL
		%if 0	; if size of forth code < 256b
			cmp	al, LASTWORD
		%else
			cmp	ax, LASTWORD
		%endif
	%endif
%endif

%if DEBUG
	;reg
%endif

%if 0 && PIC
	%if BIT == 32
		call	.below
	.below:	pop	TEMP_ADDR
		;add	TEMP_ADDR, byte (BASE-.below)
		lea	TEMP_ADDR, [A*WORD_ALIGN+embiggen(TEMP_ADDR) +(BASE-.below)]
	%else
		lea	TEMP_ADDR, [rel BASE]
		lea	TEMP_ADDR, [embiggen(TEMP_ADDR)+A]
	%endif
%else
	;lea	TEMP_ADDR, [A*WORD_ALIGN+BASE]
%endif


BP1:
%ifdef C_DOCOL
	ja	A_DOCOL
%endif
;jmpTEMP:
jmp	embiggen(TEMP_ADDR)

%define lastoff2 A_NEXT
; ABI
; esi:	Instruction pointer to next forth word
; SP:	Data stack
; DI:	Return stack
; A:	Contains value of forth word being executed.
;	Must be set =< 255 when returning from primitive
; D:	First working register for primitives
; C:	Second working register for primitives, counter register
; B:	FORTH_OFFSET of calling function. Third working register
;
; SP and DI are macros that expand to esp and edi on "32" and "x32" targets.
; They expand to rsp and rdi on target "64"
; Instruction pointer is always esi - we do not support programs bigger than 2^32 bytes
;
; Ideas what to use rbp for:
; * address of next (nope: disp8 encoding means 3 bytes)
; * zero register   (nope: mov is same or more than xor)
; * comparison register
; * counter register: only gain is not having to have rdrop
;
; Ideas for r8-15:
; * Keep part of stack
; * debug registers
;
;
; zero-A vs before:
; lit32:	+2
; divmod:	+1
; syscall3:	+2
; DOCOL:	+1
; lit8:		-2
; NEXT:		-3
; while2:	-2
; string:	-2
; TOTAL:	-3

%if FORCE_ARITHMETIC_32
	%define	aD	edx
	%define	aC	ecx
	%define arith	dword
%else
	%define	aD	D
	%define	aC	C
	%define arith	native
%endif

%ifdef C_syscall3
	%assign haveclearA	1
	%assign havepushA	1
%else
	%assign haveclearA	0
	%assign havepushA	0
%endif
%assign havepushDA	0

WORD_OFFSET:
%include "codewords.asm"

LASTWORD equ lastoff2
A___BREAK__:
END_OF_CODEWORDS:
%assign ASM_WORDS WORD_COUNT
;%define ASM_SIZE END_OF_CODEWORDS - $$ - ELF_HEADER_SIZE
%assign ASM_SIZE lastoff2 - WORD_OFFSET
%warning "ASM_SIZE" ASM_SIZE

; ################################################################

%include "immediate.asm"

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
