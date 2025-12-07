\ / 2>&-;	SCALED=${SCALED:-0} FORTHBRANCH=1 TOS_ENABLE=1 VARHELPER=1 DEBUG=${DEBUG:-} SMALLASM=${SMALLASM:-1} ./optim.sh -p fibu2.fs  && time strace -rni ./viert; exit
\ / 2>&-;	SCALED=${SCALED:-0} FORTHBRANCH=1 TOS_ENABLE=1 VARHELPER=1 DEBUG=${DEBUG:-} SMALLASM=${SMALLASM:-1} ./optim.sh fibu2.fs  && time strace -rni ./viert; exit
\ small asm:	SPLIT=1 TOS_ENABLE=1 V=1 SCALED=0 SMALLASM=1 FORTHBRANCH=1 INLINEALL=1 ./optim.sh -p fibu2.fs  && time ./viert^C
\ small+fast:	ASM="divmod swap 1+ dup drop 1- -" INLINE=1 PLUS=1 TOS_ENABLE=1 V= LIT=lit32 SMALLASM=1 FORTHBRANCH=0 LIT8=1 BRANCH8=1 SCALED=1 ./optim.sh -p $0 && time ./viert


\ / 2>&-;	SCALED=0 FORTHBRANCH=1 TOS_ENABLE=1 VARHELPER=1 DEBUG= SMALLASM=1 ./optim.sh fibu2.fs  && time ./viert; exit
\ / 2>&-;	FORTHBRANCH=1 TOS_ENABLE=1 VARHELPER=1 DEBUG= SMALLASM=1 ./optim.sh fibu2.fs  && time strace -rni ./viert; exit
 
( 
asm "rp@" 
asm "sp@" 
)
\ asm "1+"
\ asm "+"
( 
123 dbg u.
dbg 0 bye ENDPARSE
)
( 
asm "drop"
asm "1+"
asm "rpsp@"
)
( 

u.	Test if number is zero
fib	Test if number is 0 or 1

)

( 
dbg
x4+
dbg
bye
ENDPARSE
)

( 
IN 2 <
IN 2 - 0<

IN 2- 0<
IN not 1+ 1+ not 0<

)
#if PLUS
: 2- 2 - ;
: f+ + ;
#else
: 2- not 1+ 1+ not ;
: f+ q+ ;
#endif

: 2< 2- 0< ;

: fib ( n1 -- n2 )
    dup 2< if
	drop 1
    else
	dup
	1- recurse
	swap 2- recurse
	f+
    then ;

20 fib
u. cr bye
