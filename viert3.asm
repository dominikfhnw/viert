%if 0
set -euo pipefail
#set -x

#ORG="0x01000000"
#ORG="0x80000000"
ORG="0x10000"

OUT=viert
NASMOPT="-DORG=$ORG -w+all -Werror=label-orphan -Werror=number-overflow"
#NASMOPT="-DORG=$ORG -Werror=label-orphan"
if [ -n "${LINCOM-}" ]; then
	OUT="$OUT.com"
	NASMOPT="-DLINCOM=1"
	FULL=
fi

if [ -n "${FULL-1}" ]; then
	rm -f $OUT $OUT.o
	nasm -g -I asmlib/ -f elf32 -o $OUT.o "$0" $NASMOPT "$@" 2>&1 | grep -vF ': ... from macro '
	FLAGS="--print-map"
	FLAGS="-Map=%"
	FLAGS="-Map=% -Ttext-segment=$ORG"
	ld $FLAGS -m elf_i386 -z noseparate-code $OUT.o -o $OUT
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
	time nm -td -n $OUT.full
}

DUMP="-Mintel"
#DUMP="--no-addresses -Mintel"
if [ -n "${FULL-1}" ]; then
	DUMP="$DUMP -j .text -j .rodata"
	objdump $DUMP -d $OUT.full
	time symbols | mawk '/. A_/{sub(/A_/,"");if(name){print $1-size " " name};name=$3;size=$1}'|column -tR1 | sort -nr
	#time nm -td -n $OUT.full | mawk '/. A_/{sub(/A_/,"");if(name){print $1-size " " name};name=$3;size=$1}'|column -tR1 
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
%define REG_SEARCH	1
%define REG_ASSERT	0
%ifndef	LINCOM
%define LINCOM		0
%endif

%include "stdlib.mac"

%ifndef JUMPNEXT
%define JUMPNEXT	1
%endif

%define	TABLE_OFFSET	edi
%define	FORTH_OFFSET	esi
%define	NEXT_WORD	eax

%assign	WORD_COUNT	0
%define zero_seg	1

%ifndef WORD_ALIGN
%define WORD_ALIGN	1
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

; **** Macros ****
%include "macros.asm"

%if LINCOM
	[map all nasm.map]
	jmp	_start
%endif

; **** Codeword definitions ****
SECTION .text align=1
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
		;jmp	[edi + offset(ASM_OFFSET)]
		%$endasm:
		f_asmjmp
		%pop asmctx
	%endmacro
%endif
;_start:
;%define ASM_OFFSET _start
;%include "init.asm"

%include "forthwords.asm"

; **** Forth code ****
;SECTION .rodata align=1 WORD_TYPE
A_FORTH:
FORTH:
	string "hello"
	f_puts
	inline_asm
	push	12
	endasm
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
			dw (DEF%[i] - ASM_OFFSET + ELF_HEADER_SIZE)/WORD_ALIGN
		%else
			%error unsupported atm
			dd DEF%[i]
		%endif
		%assign i i+1
	%endrep
	%if WORD_SMALLTABLE
		;times (256-WORD_COUNT) dw (DEF0 - ASM_OFFSET + ELF_HEADER_SIZE)/WORD_ALIGN
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
