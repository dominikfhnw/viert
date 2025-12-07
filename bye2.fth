\ / 2>&-;	SCALED=${SCALED:-1} SMALLASM=${SMALLASM:-1} FORTHBRANCH=${FORTHBRANCH:-1} ./optim.sh $0 && setarch -R strace -rni ./viert; exit
\ asm "bye"
\ asm "rp@"
\ : 1 false 1+ ;
\ 1 if bye then
\ rp3
\ 7 65535 65536 125 syscall3_noret
\ 7 65536 dup 125 syscall3_noret

( 
666
0 0=
-8 0=
8 0=
0 dbg bye ENDPARSE
)
: poll SYS_poll syscall3_noret ;
: pollSTDIN
	1 STDIN sp@ 0 1 2pick poll
	drop drop 1- 0<>
	;

: ?key
	pollSTDIN if
		key true	
	else
		false
	then
	;


varinit foo FORTH_END
\ 12 if 84 emit then
\ 123 u.
\ 84 emit 85 emit 86 emit
(  
666
?key
0 dbg

bye ENDPARSE
)
\ 123 u.
dbg
12 u.
cr

foo @ u.
dbg bye

\ bye bye bye
( 
: spx sp3 drop swap ;

666 spx 0 dbg bye
)
