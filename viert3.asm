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
OUT=viert
if [ -n "${LINCOM-}" ]; then
	OUT="$OUT.com"
	NASMOPT="-DLINCOM=1"
	FULL=
fi

if [ -n "${FULL-1}" ]; then
	if [ "$BIT" = 64 ]
	then
		NASMOPT="$NASMOPT -f elf64 -DBIT=$BIT"
		FLAGS="$FLAGS -m elf_x86_64"
	else
		NASMOPT="$NASMOPT -f elf32 -DBIT=$BIT"
		FLAGS="$FLAGS -m elf_i386"
	fi

	echo FULL
	rm -f $OUT $OUT.o
	NASMOPT="$NASMOPT -DFULL=1"
	nasm -g -I asmlib/ -o $OUT.o "$0" $NASMOPT "$@" 2>&1 | grep -vF ': ... from macro '
	ld $FLAGS $OUT.o -o $OUT
	cp $OUT $OUT.full
	ls -l $OUT.full
	sstrip $OUT
	truncate -s -65536 $OUT
else
	echo SMALL
	NASMOPT="$NASMOPT -DBIT=$BIT"
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
	OFF=$(  readelf2 -lW $OUT 2>/dev/null | awk '$2=="0x000000"{print $3}')
	START=$(readelf2 -hW $OUT 2>/dev/null | awk '$1=="Entry"{print $4}')
	objdump $DUMP -b binary -m i386 -D $OUT --adjust-vma="$OFF" --start-address="$START"
fi

set +e
ls -l $OUT
strace -frni ./$OUT
echo ret $?
ls -l $OUT
exit

%endif

%define REG_OPT		1
%define REG_SEARCH	1
%define REG_ASSERT	0

%include "stdlib.mac"

; enable syscall words. If 0, emit/exit will use hardcoded syscalls
%ifndef SYSCALL
%define SYSCALL		1
%endif

;full ELF file. Version with FULL=0 won't have debug info/won't load in gdb at all
%ifndef FULL
%define FULL		0
%endif

; enable 8 bit literals. Usually a good idea, as it saves a lot of overall space
%ifndef LIT8
%define LIT8		1
%endif

%ifndef OFFALIGN
%define OFFALIGN	0
%endif

%ifndef BASEREG
%define BASEREG		0
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
%define zero_seg	0

%ifndef WORD_ALIGN
%define WORD_ALIGN	1
%endif

%ifndef WORD_SIZE
%define WORD_SIZE	0
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

; **** Codeword definitions ****
SECTION .text align=1

%if !FULL
	%define ELF_OFFSET 0x20
	org ORG
	ELF
%endif


A_INIT:
;_start:
; "enter" will push ebp on the stack
; This means that we can call EXIT to start the forth code at ebp
; And conveniently, EXIT is the first defined word, so we can "call" it
; by simply doing nothing
mov	ebp, FORTH
%include "init.asm"
ELF_PHDR 1
align WORD_ALIGN

ASM_OFFSET:
%include "codewords.asm"

%macro string 1
	f_string
	db %%endstring - $ - 1
	db %1
	%%endstring:
%endmacro

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

%macro doloop1 0-1
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

%macro endloop1 arg(0)
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
	f_branch
	%push elsectx
	db %$jump1 - $

	%$$jump1:
%endmacro

SECTION .text align=1
%include "forthwords.asm"

A_FORTH:
FORTH:

	lit 123456
	;f_0ne
	;f_dup
	f_dot

	;f_exit


A_END:
%if DEBUG
	; after A_END, because we don't want to count it towards the total
	A_regdump:
	%include "regdump2.mac"
%endif


%if FULL
resb 65536
%endif

%warning "SIZE" SIZE
%warning "WORDS" WORD_COUNT
