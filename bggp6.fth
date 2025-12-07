\ / 2>&-;	rm -rf ./6 && SMALLASM=${SMALLASM:-1} ./optim.sh bggp6.fth && time setarch -R strace -b execve -rni ./viert; exit
\ / 2>&-;	rm -rf ./6 && SMALLASM=${SMALLASM:-1} ./optim.sh bggp6.fth && time setarch -R strace -o trace -b execve -rni ./viert > dbg; exit
\ / 2>&-;	rm -rf ./6 && PRUNE= INLINEALL= INLINE=1 PRDEBUG= DEBUG= FULL=1 SMALLASM=1 ./optim.sh bggp6.fth && time setarch -R strace -b execve -rni ./viert; exit
: creat		  8 syscall3 ;
: open		  5 syscall3 ;
: sendfile	187 syscall3 ;
: execve	 11 syscall3 ;
: getppid	 64 syscall3 ;
: kill		 37 syscall3 ;

: print6
	stringr "6"
	writestdout
	\ rp@
	;

: creat6
	0
	'6'
	sp@
	creat
	;

: killbash
	getppid
	6
	swap
	kill
	;

: download6
	0
	string0 "6l.al"
	string0 "-L"
	dup	\ exec name can be anything
	sp@	\ array of pointers
	0	\ env
	swap

	string0 "/bin/curl"
	execve
	\ int3
	;NORETURN

: strunk
	NOINLINE
	rp@
	rpsp@
	drop
	dbg
	;


: sp2 rpsp@ nip CELL+ ;

MAIN
\ asm "0<"
\ asm "rp@"
\ 12345 10 divmod
\ asm "1+"
 
(  
 asm "1-"
 asm "dup"
\ asm "0<"
 asm "dup0<"
 asm "rp@"
\ asm "2*"
\ asm "bye"
asm "not"
asm "drop"
asm "swap"
\ )

0 hdr
1 hdr
0 if Temit then
dbg bye ENDPARSE

\ 123 .
0 if
	Temit
else
	Femit
then

1 if
	Temit
else
	Femit
then


bye ENDPARSE

\ asm "rp@"

 
( 
begin
	1 sleep
	Temit
again
)

: testf NOINLINE Bemit ;

0xDEADBEEF

\ asm "2*"
\ asm "0<"

\ Use one of the following formulas to create a word with 1’s at the positions of
\ the trailing 0’s in x, and 0’s elsewhere, producing 0 if none (e.g., 01011000 ->
\ 00000111):
: hd1 
	dup
	not
	swap
	dec
	and
	;

\ Use the following formula to turn on the trailing 0’s in a word, producing x if
\ none (e.g., 10101000 -> 10101111):
: hd2 dup 1- or ;

\ Use the following formula to create a word with 0’s at the positions of the
\ trailing 1’s in x, and 1’s elsewhere, producing all 1’s if none (e.g., 10100111 ->
\ 11111000)
: hd3 dup 1+ swap not or ;

\ Use the following formula to create a word with 1’s at the positions of the
\ rightmost 1-bit and the trailing 0’s in x, producing all 1’s if no 1-bit, and the inte-
\ ger 1 if no trailing 0’s (e.g., 01011000 -> 00001111):
: hd4 dup 1- xor ;

\ Use the following formula to create a word with 1’s at the positions of the
\ rightmost 0-bit and the trailing 1’s in x, producing all 1’s if no 0-bit, and the inte-
\ ger 1 if no trailing 1’s (e.g., 01010111 -> 00001111)
: hd5 dup 1+ xor ;

: hr1  dup 1- and ;
: hr2  dup 1+ or ;
: hr3  dup 1+ and ;
: hr4  dup 1- or ;
: hr5  dup not swap 1+ and ;
: hr6  dup not swap 1- or ;
: hr7  dup not swap 1- and ;
: hr8  dup not swap 1+ or ;
: hr9  dup not and ;
: hr10 dup 1- xor ;
: hr11 dup 1+ xor ;
: hr11 dup 1+ xor ;

variable val
( cand: hr4 hr6 hr7 hr10 )
:x hd hr11 not ;
:x hdx hr6 not maxb  ;

:x hd hr4 not maxb ;
:x hdx hr6 not maxb ; \ beter maxb than hr4
:x hd hr7 not maxb ; \ better maxb than hr10
:x hdx hr10 not maxb ;

:x hd hr6 not ; \ beter maxb than hr4

: hd goo2 not ;
:x hdx hr7 not ; \ better maxb than hr10. natural maxb
: hdx  dup not swap 1- nand ;
: allhd
	val !
	0xDEADBEEF
	val @ hd1
	val @ hd2
	val @ hd3
	val @ hd4
	val @ hd5
	dbg
;

: allhr
	val !
	0xDEADBEEF
	 val @ hr1
	\ val @ hr2
	 val @ hr3
	val @ hr4
	\ val @ hr5
	val @ hr6
	val @ hr7
	 val @ hr8
	 val @ hr9
	val @ hr10
	\ val @ hr11
	dbg
;

\ 0		allhr
\ 123457		allhr

( hr4 hr6 hr7 hr10 ) 
 
( 
0		allhr
0x80000000	allhr
0		1+ allhr
0x80000000	1+ allhr
0		1- allhr
0x80000000	1- allhr

0		0x80000001 + allhr
0x80000000	0x80000001 + allhr
( 
12 allhd
-1 allhd
-42392 allhd

)

 
(   
0xDEADBEEF
0 goo2 not
0x80000000 goo2 not
0 hdr
12 hdr 

dbg

 
0xDEADBEEF
0 hdr
0x80000000 hdr

dbg
)

  
0xDEADBEEF
0	hdr
1	hdr
-12	hdr
10244	hdr

dbg


0xDEADBEEF
0	hdr3
1	hdr3
-12	hdr3
10244	hdr3

dbg


bye ENDPARSE

val 0=1
val 0=2
val 0=4

0xCAFEBABE

val goo2

( 
2dup and
dup
not gaa not
) 
dbg bye ENDPARSE

\ 123456789 u.
\ 8000000 dup q+

\ 4000 sp@ @ dbg +
\ 1234 .
bye ENDPARSE

\ asm "0<>"
\  asm "0<"
true
if
	Temit
then

dbg bye
0<
ENDPARSE


10 2 divmod
dbg
bye ENDPARSE
4000000
dup + dbg
bye
ENDPARSE
\ true dup + not dbg bye
\ ENDPARSE
0 if Temit else Femit then
-0 if Temit else Femit then
1 if Temit else Femit then
-1 if Temit else Femit then
12 if Temit else Femit then

bye ENDPARSE

616 666 <>
\ 4 2 dbg
\ xor

dbg bye
ENDPARSE

300 dup 0< swap negate 0<
dbg bye
\ -1 0< 1 0< dbg bye
ENDPARSE
1 u. bye
( 
\ 666 dbg
dH demit
dE demit
\ dL dup demit demit
dL demit
dL demit
dO demit
dbang demit
dnl demit
bye

ENDPARSE
)
\ strunk
\ 1 CELL*2+ 
\ 48 5 xx+
sp@ sp2 sp@ dbg
bye
( 

100ce is what we want
0xffffcee4│+0x0004: 0x000100ce  →   add DWORD PTR [eax], eax
0xffffcee0│+0x0000: 0x000100c4  →  <Z_xlit32_72._int3_27+0000> pop ds    ← $esp

0xffffcee4│+0x0004: 0x000100ce  →   add DWORD PTR [eax], eax


)
( 
12 not 1+ not u.
bye
\ 1 1 = u.
2 2 = if 84 emit else 70 emit then
\ 2 2 = u.
bye
1+
)
 
( 
rsdrop rsdrop r@ open
\ dbg
0	\ last param for sendfile
creat6
\ dbg
sendfile
\ dbg

killbash

download6
)
\ print6
\ bye
