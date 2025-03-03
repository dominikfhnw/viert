%if 0
set -euo pipefail
#set -x

#ORG="0x01000000"
#ORG="0x80000000"
ORG="0x10000"
DUMP="-Mintel"
#DUMP="--no-addresses -Mintel"
NASMOPT="-DORG=$ORG -w+all -Werror=label-orphan -Werror=number-overflow"
#NASMOPT="-DORG=$ORG -w+all -Werror=label-orphan"
FLAGS="-Map=% -Ttext-segment=$ORG -z noseparate-code"
#FLAGS="-Map=% -Ttext-segment=$ORG"

BIT=32
if [ "$BIT" = 64 ]
then
	NASMOPT="$NASMOPT -f elf64 -DBIT=$BIT"
	FLAGS="$FLAGS -m elf_x86_64"
else
	NASMOPT="$NASMOPT -f elf32 -DBIT=$BIT"
	FLAGS="$FLAGS -m elf_i386"
fi

OUT=viert
if [ -n "${LINCOM-}" ]; then
	OUT="$OUT.com"
	NASMOPT="-DLINCOM=1"
	FULL=
fi

if [ -n "${FULL-1}" ]; then
	rm -f $OUT $OUT.o
	nasm -g -I asmlib/ -o $OUT.o "$0" $NASMOPT "$@" 2>&1 | grep -vF ': ... from macro '
	ld $FLAGS $OUT.o -o $OUT
	cp $OUT $OUT.full
	ls -l $OUT.full
	sstrip $OUT
	truncate -s -65536 $OUT
else
	rm -f $OUT
	nasm -I asmlib/ -f bin -o $OUT "$0" $NASMOPT "$@" 2>&1 | grep -vF ': ... from macro '
fi
ls -l $OUT
chmod +x $OUT

symbols(){
	#time LC_ALL=C nm -f bsd -td -n $OUT.full
	time LC_ALL=C eu-nm -f bsd -td -n $OUT.full
}
sizes(){
	time symbols | mawk '/. A_[^.]*$/{sub(/A_/,"");if(name){print $1-size " " name;total+=($1-size)};name=$3;size=$1}END{total+=84;print total " TOTAL"}BEGIN{print "84 ELF"}'|column -tR1
}

if [ -n "${FULL-1}" ]; then
	DUMP="$DUMP -j .text -j .rodata"
	objdump $DUMP -d $OUT.full
	#sizes | sort -nr
	sizes
else
	#OFF=$(  readelf2 -lW $OUT 2>/dev/null | awk '$2=="0x000000"{print $3}')
	OFF="0x10000"
	#START=$(readelf2 -hW $OUT 2>/dev/null | awk '$1=="Entry"{print $4}')
	START="0x10000"
	objdump $DUMP -b binary -m i386 -D $OUT --adjust-vma="$OFF" --start-address="$START"
fi

set +e
ls -l $OUT
strace -frni ./$OUT
echo ret $?
exit

%endif

%define REG_OPT		1
%define REG_SEARCH	0
%define REG_ASSERT	0
%ifndef	LINCOM
%define LINCOM		0
%endif

%include "stdlib.mac"

%ifndef BIGJMP
%define BIGJMP		0
%endif

%ifndef THRESH
%define THRESH		1
%endif

%ifndef OFFALIGN
%define OFFALIGN	0
%endif

%ifndef BASEREG
%define BASEREG		1
%endif

%if BIT == 64
	%define	BASE		rdi
	%define	RETURN_STACK	rbp
	%define	FORTH_OFFSET	rsi
	%define	NEXT_WORD	rax
	%define	native		qword
%else
	%define	BASE		edi
	%define	RETURN_STACK	ebp
	%define	FORTH_OFFSET	esi
	%define	NEXT_WORD	eax
	%define	native		dword
%endif

%assign	WORD_COUNT	0
%define zero_seg	1

%ifndef WORD_ALIGN
%define WORD_ALIGN	2
%endif

%ifndef WORD_FOOBEL
%define WORD_FOOBEL	0
%endif

%ifndef WORD_SIZE
%define WORD_SIZE	1
%endif

; XXX quick&dirty hack
%if   WORD_SIZE == 0
	%define WORD_TABLE	0
	%define WORD_SMALLTABLE 0
	%define lodsWORD lodsb
	%define WORD_TYPE byte
	%define WORD_DEF db
	%define WORD_SIZE 1

%elif WORD_SIZE == 1
	%define WORD_TABLE	1
	%define WORD_SMALLTABLE 1
	%define lodsWORD lodsb
	%define WORD_TYPE byte
	%define WORD_DEF db
	%define WORD_ALIGN 1
%elif WORD_SIZE == 2
	%define WORD_TABLE	0
	%define WORD_SMALLTABLE 0
	%define lodsWORD lodsw
	%define WORD_TYPE word
	%define WORD_DEF dw
	%define WORD_ALIGN 1
%elif WORD_SIZE == 4
	%define WORD_TABLE	0
	%define WORD_SMALLTABLE 0
	%define lodsWORD lodsd
	%define WORD_TYPE dword
	%define WORD_DEF dd
	%define WORD_ALIGN 1
%else
	%error illegal word size WORD_SIZE
%endif

; 52 byte for ELF header, 32 byte for each program header
%define elf_extra_align 0
%if WORD_ALIGN == 8
	%define elf_extra_align 4
%endif
%define ELF_HEADER_SIZE (52 + 1*32 + elf_extra_align)

%if OFFALIGN
	%if !BASEREG
		%define BASE ORG
	%endif
%else
	%if !BASEREG
		%define BASE ASM_OFFSET
	%endif
%endif

; **** Macros ****
%include "macros.asm"

%if LINCOM
	[map all nasm.map]
	jmp	_start
%endif

; **** Codeword definitions ****
SECTION .text align=1
A_INIT1:
_start:
; "enter" will push ebp on the stack
; This means that we can call EXIT to start the forth code at ebp
; And conveniently, EXIT is the first defined word, so we can "call" it
; by simply continuing
mov	ebp, FORTH
enter	0xFFFF, 0

ASM_OFFSET:
%include "codewords.asm"

%macro string 1
	f_string
	db %%endstring - $ - 1
	db %1
	%%endstring:
%endmacro

%if 0
	%macro inline_asm 0
		%push asmctx
		f_asmret
		db %$endasm - $ - 1
		%$asm:
	%endmacro

	%macro endasm 0
		NEXT
		%$endasm:
		%pop asmctx
	%endmacro
%else
	%macro inline_asm 0
		%push asmctx
		f_string
		db %$endasm - $ - 1
		%$asm:
	%endmacro

	%macro endasm 0
		NEXT
		%$endasm:
		f_asmjmp
		%pop asmctx
	%endmacro
%endif

%macro doloop 0-1
	%push loopctx
	%if %0 == 1
		lit %1
	%endif
	f_rspush
	%$loop:
%endmacro

%macro endloop0 arg(0)
	;f_rsdec
	;f_dupr2d
	;f_zbranch
	f_while
	db %$loop - $ - 1
	;f_rspop
	; f_drop
	%pop loopctx
%endmacro

%macro endloop arg(0)
	f_while2
	db $ - %$loop + 1
	%pop loopctx
%endmacro

%macro endloop2 arg(0)
	f_loopdec
	f_zbranch
	db $ - %$loop + 1
	%pop loopctx
%endmacro

%macro if arg(0)
	%push ifctx
	f_zbranch
	db %$jump1 - $
%endmacro

%macro then arg(0)
	%$jump1:

	%ifctx elsectx
		%pop elsectx
	%endif
	%pop ifctx
%endmacro

%macro else arg(0)
	;string "else"
	;f_puts

	f_branch
	%push elsectx
	db %$jump1 - $

	%$$jump1:
%endmacro

%include "forthwords.asm"

;_start:
%include "init.asm"
;jmp	A_NEXT


; **** Forth code ****
;SECTION .rodata align=1 WORD_TYPE

A_FORTH:
FORTH:

	lit 0
	f_bool
	f_dup
	f_dot

	f_exit

	lit -12
	f_dup
	f_dot
	f_negate
	f_dot


	f_true
	;f_false
	if
		string "true1"
		f_puts
	;else
	;	string "false1"
	;	f_puts
	then
	string "end1"
	f_puts

	doloop 3
		;lit 1
		;f_plus
		f_inc
	endloop
	f_dot

	f_exit

;	f_false
;	if
;		string "true2"
;		f_puts
;	else
;		string "false2"
;		f_puts
;	then
;	string "end2"
;	f_puts
;	f_exit




;	lit 8
;	f_rspush
;
;	.loop:
;	f_char
;	f_rsdec
;	f_dupr2d
;	f_zbranch
;	db .loop - $ - 1
	;doloop 10000000
	;inline_asm
	;push	12
	;endasm
	f_exit
%if 0
	;f_exit
	;string "hello, world!"
	;f_puts
	;f_mem
	;lit -1
	;f_dot
	lit 0
	f_dup
	f_dot
	lit 1
	f_dup
	f_dot
	f_fib
	f_exit
%endif

;%if 0
;	lit 8
;	lit 14
;	f_plus
;	f_dot
;%endif
;
;%if 0
;	inline_asm
;	push	12
;	endasm
;%endif
;
;%if 0
;	lit 10
;	lit 8
;	f_plus
;	;lit 123456789
;	f_dot
;%endif
;%if 0
;	lit 8
;	.loop:
;	f_char
;	f_dec
;	f_zbranch
;	db .loop - $ - 1
;	f_nl
;	string "finished"
;	f_puts
;	f_nl
;%endif
;	;string `\033[G\033[F\033[JFoobar`
;	;string `\033[A\033[G\033[J`
;	;string `\033[A\033[20D\033[Jclose(0`
;	;f_xputs
;
;
	f_exit



; **** Jump table ****
SECTION .rodata align=1 
%if WORD_TABLE
	STATIC_TABLE:
	A_STATIC_TABLE:
	%warning WORD COUNT: WORD_COUNT
	%assign	i 0
	%rep	WORD_COUNT
		%if WORD_SMALLTABLE
			dw offset(DEF%[i])
		%else
			;%error unsupported atm
			dd DEF%[i]
		%endif
		%assign i i+1
	%endrep
	%if WORD_SMALLTABLE
		;times (256-WORD_COUNT) dw offset(DEF0)
		;resw (256-WORD_COUNT)
	%else
		;times (256-WORD_COUNT) dd DEF1
	%endif
	A_END_TABLE:
	;db "gugus"
%endif
A_REALLY_END:

resb 65536
; **** Assembler code ****
;SECTION .text.startup align=1
SECTION .text align=1
%if DEBUG
A_regdump:
%include "regdump2.mac"
%endif
