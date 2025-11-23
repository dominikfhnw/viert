#!/bin/bash
set -ue
FILE=$1
shift
#cat lib-rp.fth $FILE > tmp.fth
CPP="-DPLUS"
CPP=""
cpp $CPP -C -P -nostdinc lib-rp.fth > tmp.fth
cat $FILE >> tmp.fth
export OPT
export PRUNE
export INLINE
export INLINEALL
export DEBUG
export PRDEBUG
export LIT8
export SMALLINIT
export FORTHBRANCH
export WORD_ALIGN
export SCALED
#OPT=${OPT-} perl p2.pl tmp.fth 2> x > f2
#echo "PRUNE $PRUNE"
#echo "INLINEALL $INLINEALL"
perl p2.pl tmp.fth 2> x > f2

bash -x ./f2 "$@"

