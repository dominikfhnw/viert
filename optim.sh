#!/bin/bash
set -ue
FILE=$1
shift
#cat lib-rp.fth $FILE > tmp.fth

# LIBRARY DEFINES:
# PLUS: word "+" available
# XLIT: support for xlit32
# MOO: equality ("=") with XOR
# CHAIN: u. as a continue-chain


CPP="-DPLUS -DXLIT"
CPP="-DPLUS"
CPP=""

CPP="-DPLUS -DXLIT"
CPP="-DXLIT"
CPP="-DPLUS"
CPP="-DPLUS -DXLIT"
CPP="-DXLIT -DMOO -DCHAIN"
CPP="-DMOO -DXLIT"
cpp $CPP -C -P -nostdinc lib-rp2.fth > tmp.fth
cat $FILE >> tmp.fth
export OPT
export PRUNE
export INLINE
export INLINEALL
export DEBUG
export PRDEBUG
export LIT8
export LIT
export SMALLINIT
export FORTHBRANCH
export WORD_ALIGN
export SCALED
export FULL
#OPT=${OPT-} perl p2.pl tmp.fth 2> x > f2
#echo "PRUNE $PRUNE"
#echo "INLINEALL $INLINEALL"
perl p2.pl tmp.fth 2> x > f2

bash -x ./f2 "$@"

