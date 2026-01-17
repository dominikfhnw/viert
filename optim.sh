#!/bin/bash
set -ue
FILE=$1
shift
PREPROC=
if [ "$FILE" = "-p" ]; then
	PREPROC=1
	FILE=$1
	shift
fi

nl='
'

CPP=
EXTRA=
for i in ${ASM-}
do
	EXTRA="${EXTRA}asm \"$i\"$nl"
	CPP="$CPP -DASM_$i=1"
done

if [ "${BIT-}" = "x32" ]; then
	BITS=64
	X32=1
else
	BITS=${BIT:-32}
fi

# LIBRARY DEFINES:
# PLUS: word "+" available
# XLIT: support for xlit32
# CHAIN: u. as a continue-chain
: "${TOS_ENABLE=1}"
for i in BIT BITS DEBUG FULL WORD_ALIGN SCALED TOS_ENABLE FORTHBRANCH PRUNE INLINE INLINEALL PRDEBUG LIT8 BRANCH8 SMALLASM PLUS VARHELPER XLIT FORCE JMPLEN SMALLINIT X32 FORCE_ARITHMETIC_32 SYSCALL64 CHAIN DIS HARDEN WORDS_FIRST
do
	if [ -n "${!i-}" ]; then
		CPP="$CPP -D$i=${!i}"
	fi
done
echo "$CPP"
export TOS_ENABLE

if [ "${V-}" ]; then
	LIB="lib-var.fth"
else
	LIB="lib-rp.fth"
fi


OUT="tmp.fth"
echo "$EXTRA" > "$OUT"
CMD="cpp $CPP -C -P -nostdinc"
$CMD "$LIB" >> "$OUT"
if [ $PREPROC ]; then
	$CMD "$FILE" >> "$OUT"
else
	cat $FILE >> "$OUT"
fi



if perl p2.pl "$OUT" 2> x > f2
then
	:
else
	ret=$?
	tail -20 x
	echo "p2 error $ret"
	exit $ret
fi

bash -x ./f2 "$@"

