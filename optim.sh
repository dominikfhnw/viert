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

EXTRA=
for i in ${ASM-}
do
	EXTRA="${EXTRA}asm \"$i\"$nl"
done

if [ "${BIT-}" = "x32" ]; then
	BITS=64
else
	BITS=${BIT:-32}
fi

# LIBRARY DEFINES:
# PLUS: word "+" available
# XLIT: support for xlit32
# CHAIN: u. as a continue-chain
: "${TOS_ENABLE=1}"
CPP=
for i in BIT BITS DEBUG FULL WORD_ALIGN SCALED TOS_ENABLE FORTHBRANCH PRUNE INLINE INLINEALL PRDEBUG LIT8 BRANCH8 SMALLASM PLUS VARHELPER XLIT FORCE JMPLEN
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
cpp $CPP -C -P -nostdinc "$LIB" >> "$OUT"
if [ $PREPROC ]; then
	cpp $CPP -C -P -nostdinc "$FILE" >> "$OUT"
else
	cat $FILE >> "$OUT"
fi



perl p2.pl "$OUT" 2> x > f2

bash -x ./f2 "$@"

