#!/bin/bash
set -euo pipefail

BIT="32"
HARDEN=0
#ORG="0x01000000"
#ORG="0x80000000"
ORG="0x10000"
DUMP="-z -Mintel"
#DUMP="--no-addresses -z -Mintel"
#NASMOPT="-g -DORG=$ORG -w+all -Werror=label-orphan"
#NASMOPT="-g -DORG=$ORG -w+all -Werror=label-orphan -L+ -l nasm.list"
NASMOPT="-g -DORG=$ORG -w+all -Werror=label-orphan -Lemp -l nasm.list"
#NASMOPT="-g -DORG=$ORG -w+all"
if [ -z "${FORCE-}" ]; then
	NASMOPT="$NASMOPT -Werror=number-overflow"
else
	NASMOPT="$NASMOPT -DFORCE=1"
fi
if [ -n "${LIT-}" ]; then
	NASMOPT="$NASMOPT -DLIT=$LIT"
fi
if [ -n "${TOS_ENABLE-}" ]; then
	NASMOPT="$NASMOPT -DTOS_ENABLE=$TOS_ENABLE"
fi
if [ -n "${SPLIT-}" ]; then
	NASMOPT="$NASMOPT -DSPLIT=$SPLIT"
else
	NASMOPT="$NASMOPT -DSPLIT=0"
	SPLIT=0
fi
NASMOPT="$NASMOPT -DFORTHBRANCH=${FORTHBRANCH-0}"
NASMOPT="$NASMOPT -DJMPLEN=${JMPLEN-short}"

LD="gold"
#LD="ld.lld"
LD="ld"
#LD="/home/balou/ELFkickers-3.2/infect/f/isvm-tool/viert.proj/mold/build/mold"

if [ -z "${PIC-}" ]; then
	if [ "$LD" != "ld.lld" ]; then
		FLAGS="-Ttext-segment=$ORG"
	else
		FLAGS="--image-base $ORG"
	fi
else
	FLAGS="-pie --no-dynamic-linker -z norelro --hash-style=sysv --no-eh-frame-hdr --disable-new-dtags --no-ld-generated-unwind-info --as-needed"
	FLAGS="-pie --no-dynamic-linker -z norelro --hash-style=sysv"
	#FLAGS="-pie --no-dynamic-linker -z relro -z noexecstack -z now --hash-style=sysv --export-dynamic-symbol=__stack_chk_fail"
	#FLAGS="-pie --no-dynamic-linker -z relro -z noexecstack -z now --hash-style=sysv --export-dynamic-symbol=__stack_chk_fail --build-id=sha1"
	NASMOPT="$NASMOPT -DPIC=1"
fi

if [ "$LD" != "gold" ]; then
	FLAGS="$FLAGS -z noseparate-code"
fi

if [ "$HARDEN" = 1 ]; then
	NASMOPT="$NASMOPT -DHARDEN=1"
	FLAGS="$FLAGS -static -pie --no-dynamic-linker"
	#FLAGS="$FLAGS -T o --verbose -u __stack_chk_fail -u __read_chk -z noexecstack -z ibt -z shstk -z relro -z now --build-id=none --orphan-handling=warn"
	#FLAGS="$FLAGS -u __stack_chk_fail -u __read_chk -u .cfi -u __safestack_init -z noexecstack -z ibt -z shstk -z relro -z now --build-id=none --orphan-handling=warn"
	FLAGS="$FLAGS -u __stack_chk_fail -u __read_chk -u .cfi -u __safestack_init -z noexecstack -z ibt -z shstk -z relro -z now --build-id=none"
	FLAGS="$FLAGS -u .cfi -u __safestack_init" # checksec extended
	FLAGS="$FLAGS --unresolved-symbols=report-all"
else
	if [ "${LD##*/}" = "mold" ]; then
		FLAGS="$FLAGS --no-eh-frame-hdr -z norelro"
	elif [ "$LD" = "ld.lld" ]; then
		FLAGS="$FLAGS -z nognustack --no-rosegment"
	fi
fi
#FLAGS="$FLAGS --relax --enable-non-contiguous-regions --no-check-sections --no-fatal-warnings --no-warn-mismatch --noinhibit-exec  --warn-unresolved-symbols"
#FLAGS="$FLAGS --noinhibit-exec --build-id"
FLAGS="$FLAGS --noinhibit-exec"
if [ "$SPLIT" -eq 0 ]; then
	FLAGS="$FLAGS --omagic"
fi

if [ -z "${RAW-}" ]; then
	DEBUG=${PRDEBUG-0} LIT8=${LIT8-1} perl parse.pl "${SOURCE:-forthwords.fth}" > compiled.asm 2> db.parse1
else
	cp "$RAW" compiled.asm
fi


OUT=viert
if [ -n "${LINCOM-}" ]; then
	OUT="$OUT.com"
	NASMOPT="$NASMOPT -DLINCOM=1"
	FULL=
fi

preproc(){
	{ nasm -I asmlib/ -e viert3.asm $NASMOPT "$@" ||:; } 2> preproc.err | grep -Ev '^(%line|$)' | sed '/:$/s/^/\n/' > preproc.asm
}

if [ -n "${FULL-1}" ]; then
	if [ "$BIT" = 64 ]
	then
		echo "Mode: full x64"
		NASMOPT="$NASMOPT -f elf64 -DBIT=$BIT"
		FLAGS="$FLAGS -m elf_x86_64"
	elif [ "$BIT" = "x32" ]
	then
		echo "Mode: full x32"
		NASMOPT="$NASMOPT -f elfx32 -DBIT=64 -DX32=1"
		FLAGS="$FLAGS -m elf32_x86_64"
	else
		echo "Mode: full 386"
		NASMOPT="$NASMOPT -f elf32 -DBIT=$BIT"
		FLAGS="$FLAGS -m elf_i386"
	fi

	echo "FULL $BIT"
	rm -f $OUT $OUT.o
	NASMOPT="$NASMOPT -DFULL=1"
	#nasm -I asmlib/ -o $OUT.o "$0" $NASMOPT "$@" 2>&1 | grep -vF ': ... from macro ' | grep -a --color=always -E '|error:'
	nasm -I asmlib/ -o $OUT.o viert3.asm $NASMOPT "$@" 2>&1 | grep -a --color=always -E '|error:'
	preproc
	$LD $FLAGS $OUT.o -o $OUT || { echo "ERROR $?"; exit; }
	cp $OUT $OUT.full
	ls -l $OUT.full
	sstrip $OUT
	#truncate -s -65536 $OUT

	if [ "$HARDEN" = 1 ]; then
		echo
		echo " * hardening-check:"
		hardening-check -c viert.full ||:

		echo
		echo " * checksec:"
		checksec --file=viert.full ||:
		exit
	fi
else
	echo "SMALL $BIT"
	if [ "$BIT" = "x32" ]
	then
		NASMOPT="$NASMOPT -DBIT=64 -DX32=1"
	else
		NASMOPT="$NASMOPT -DBIT=$BIT"
	fi

	if [ "$BIT" != 32 ]
	then
		echo "Oh hell no" >&2
		#exit 66
	fi
	rm -f $OUT
	nasm -I asmlib/ -f bin -o $OUT viert3.asm $NASMOPT "$@" 2>&1 | grep -vF ': ... from macro '
	preproc
fi
chmod +x $OUT
ls -l $OUT

symbols(){
	# binutils nm sometimes has a weird ~0.5s lag, while eu-nm is consistently fast
	OPT="-f bsd -td -n $OUT.full"
	time LC_ALL=C eu-nm $OPT || nm $OPT
}
sizes(){
	symbols | awk '
		BEGIN {
			elf=84
			total=elf
			print elf, "ELF"
		}

		/. A_[^.]*$/ {
			sub(/A_/,"")
			if(name == "__BREAK__"){
				print total, "SUBTOTAL"
				subtotal = total
				asm = total-elf
				print asm, "ASM"
			}
			else if(name){
				print $1-size, name
				total+=($1-size)
			}
			if(name == "MAIN"){
				print total-subtotal, "FORTH"
				print total-subtotal+asm, "CODE"
			}
			name=$3
			size=$1
		}

		END {
			print total " TOTAL"
		}
	'|column -tR1
}

#r2 -2 -c aa -c 'e emu.str = true' -c 'pD $SIZE @ entry0' -q $
#RADARE="r2 -2 -c aa -c 'e emu.str = true' -c 'pdf' -q"
#RADARE="r2 -2 -c aa -c pdf -q"
#set -x
R2=

if [ -n "${FULL-1}" ]; then
	SIZE=$(( $(wc -c < "$OUT") - 84 ))
	RADARE="r2 -2 -c aa -c 'e emu.str = true' -c 'pD $SIZE @ entry0' -q"
	DUMP="$DUMP -j .text -j .data -j .rodata"
	if [ "${DIS-1}" ]; then
		if [ "${R2-}" ]; then
			time eval $RADARE "$OUT.full"
		else
			objdump $DUMP -d $OUT.full
		fi
	fi
	#sizes | sort -nr
	sizes
else
	if [ "${DIS-1}" ]; then
		if :; then
			if [ "$BIT" = "x32" ]; then
				m="x86-64"
			else
				m="i386"
			fi
			if [ -n "${LINCOM-}" ]; then
				OFF="0x10000"
				START="0x10000"
			else
				OFF=$(  readelf -lW $OUT 2>/dev/null | awk '$2=="0x000000"{print $3}')
				START=$(readelf -hW $OUT 2>/dev/null | awk '$1=="Entry"{print $4}')
			fi
			echo "OFF $OFF START $START"
			objdump $DUMP -b binary -m i386 -M $m -D $OUT --adjust-vma="$OFF" --start-address="$START"
		else
			eval $RADARE "$OUT"
		fi
	fi
fi

ls -l $OUT
if [ "${RUN-1}" ]; then
	set +e
	strace -frni ./$OUT
	echo ret $?
	ls -l $OUT
	set -e
fi
exit
