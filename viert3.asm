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

; enable 8 bit literals. Usually a good idea, as it saves a lot of overall space
%ifndef LIT8
%define LIT8		1
%endif

; branching with 8 bit values. Bigger asm part because of movsx, probably smaller overall
%ifndef BRANCH8
%define BRANCH8		1
%endif

%if BRANCH8
	%macro dbr 1
		;%warning BRANCH8 %1
		db %1 - $
	%endmacro
	%define incbr	lodsb
%else
	%macro dbr 1
		;%warning BRANCH32 %1
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

%ifndef OFFALIGN
%define OFFALIGN	0
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

%if OFFALIGN
	%define BASE ORG
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
; "enter" will push ebp on the stack
; This means that we can call EXIT to start the forth code at ebp
; And conveniently, EXIT is the first defined word, so we can "call" it
; by simply doing nothing
%if HARDEN
hardening:
%if BIT == 64
	cmp	rsp, rsp 
%else
	cmp	ax, 4096
%endif
jz	.end
sub	ax, 4096
or	al, 0
jmp	hardening
.end:
%if BIT != 64
rset	eax, 4096
set	eax, 0
%endif
%endif

%if 1
	enter	0xFFFF, 0
	%ifnidn embiggen(RETURN_STACK),BP
		%if X32
			xchg	RETURN_STACK,ebp
		%else
			xchg	RETURN_STACK,BP
		%endif
	%endif
	ELF_PHDR 1
	; we chose our base address to be < 2^32
	%if PIC
		lea	TEMP_ADDR, [rel FORTH]
	%else
		mov	TEMP_ADDR, FORTH
	%endif
%else
	; we chose our base address to be < 2^32
	mov	ebp, FORTH
	enter	0xFFFF, 0
	ELF_PHDR 1
	%ifnidn embiggen(RETURN_STACK),BP
		%if X32
			xchg	RETURN_STACK,ebp
		%else
			xchg	RETURN_STACK,BP
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

%macro do arg(0)
	%push dountilctx
	%$dountil:
%endmacro

%macro until arg(0)
	f_zbranch
	dbr %$dountil
	%pop dountilctx
%endmacro

%macro while arg(0)
	f_not
	f_zbranch
	dbr %$dountil
	%pop dountilctx
%endmacro

;%macro doloop1 0-1
;	%push loopctx
;	%if %0 == 1
;		lit %1
;	%endif
;	f_rspush
;	%$loop:
;%endmacro
;
;%macro endloop3 arg(0)
;	f_while2
;	db $ - %$loop + 1
;	%pop loopctx
;%endmacro
;
;%macro endloop1 arg(0)
;	%if FORTHWHILE
;		f_rp_at
;		f_while
;		f_zbranch
;		dbr %$loop
;		f_rdrop
;	%else
;		f_while2
;		db $ - %$loop + 1
;	%endif
;	%pop loopctx
;%endmacro
;
;%macro endloop2 arg(0)
;	f_while4
;	db $ - %$loop + 1
;	f_rdrop
;	%pop loopctx
;%endmacro

%macro unless arg(0)
	;%push ifctx
	;f_nzbranch
	;dbr %$jump1
	if
	else
%endmacro

%macro if arg(0)
	%push ifctx
	f_zbranch
	dbr %$jump1
%endmacro

%macro then arg(0)
	%$jump1:
	%ifctx elsectx
		%pop elsectx
	%endif
	%pop ifctx
%endmacro
%defalias endif then

%macro else arg(0)
	f_branch
	%push elsectx
	dbr %$jump1

	%$$jump1:
%endmacro

%macro jump arg(1)
	f_branch
	dbr %1
%endmacro

%macro begin 0
	%push beginloop
	%$loop:
%endmacro

%macro again 0
	f_branch
	dbr %$loop
	%pop beginloop
%endmacro

%macro for 0
	f_rspush
	%push forloop
	%$forloop:
%endmacro

%macro next 0
%$i:	f_i
%$dec:	f_dec
%$dup:	f_dup
%$rpfe:	f_rpfetch
%$stor:	f_store

%$if:
if

%$branch:
	f_branch
	dbr %$$forloop ; we're inside an ifctx
%$then:
then
%$rsdrop:
f_rsdrop
%$end:
	%pop forloop
%endmacro

FORTH_START:
%include "compiled.asm"

A_END:
%if DEBUG
	; after A_END, because we don't want to count it towards the total
	A_regdump:
	%include "regdump2.mac"
%endif


%if FULL
;resb 65536
%endif

%if HARDEN
SECTION txtrp align=1
db 0
%endif
%assign FORTH_WORDS WORD_COUNT - ASM_WORDS
%define FORTH_SIZE %eval(lastoff2 - FORTH_START)
%warning "ASM_SIZE" ASM_SIZE
%warning "ASM_WORDS" ASM_WORDS
%warning "ASM_RATIO" %eval(ASM_SIZE/ASM_WORDS)
%warning "FORTH_SIZE" FORTH_SIZE
%warning "FORTH_WORDS" FORTH_WORDS
;%warning "FORTH_RATIO" %eval(FORTH_SIZE/FORTH_WORDS)
%warning "WORDS TOTAL" WORD_COUNT
%warning "BREAK" %eval(BREAK)
%warning "LASTOFF" %eval(lastoff)
%warning "LASTOFF2" %eval(((lastoff2 - $$)/WORD_ALIGN)+ELF_HEADER_SIZE)
