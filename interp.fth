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

varinit HERE FORTH_END
varinit LATEST LATEST
\ varinit EEE FORTH_END

: allot HERE @ + HERE ! ;
: cells 0 begin CELL+ swap 1- swap over 0< until CELL- ;
\ : , ( a -- ) HERE @ ! HERE CELL+ HERE ! ;
: , ( a -- )
	HERE @ !		\ store
	HERE @ CELL+ HERE !	\ increase
	;

: c, ( a -- )
	HERE @ !		\ store
	HERE @ 1+ HERE !	\ increase
	;

\ variable wstring 16 allot
vararray wstring 16

: c@ @ 0xff and ;
: c!
	swap 0xff and
	over @ 0xff not and
	\ 0xDEADBEEF dbg drop
	or
	\ 0xDEADBEEF dbg drop
	swap !
	;

: word0
	begin
		key dup
	33 >= until

	t0
	begin
		t1+@
		wstring + !
		\ emit
		key dup
	33 < until

	drop
	t> wstring c!
	wstring
	;

: parse2
	begin
		key dup
	33 >= until

	t0
	begin
		t@
		wstring + !
		\ emit
		t1+
		key dup
	33 < until

	drop
	t>
	wstring
	;

: parse0
	ANYLIT
	begin
		drop key dup
	33 >= until

	t0

	begin
		t@ wstring + !
		t1+
		key dup
	33 < until

	drop
	t>
	wstring
	;

: varinc dup @ dbg 1+ swap
	\ 0 dbg drop
	 ! ;

: 33+ 32+ 1+ ;
: 33- not 33+ not ;
#if PLUS
: 33< 33 < ;
#else
: 33< 33- 0< ;
#endif
variable pp
: parse3
	ANYLIT
	begin
		drop key dup
	33< not until

	t0
	wstring pp !

	begin
		pp @ !
		pp @ 1+ pp !
		t1+
		key dup
	33< until

	drop
	t>
	wstring
	;
	
#if PLUS
: parse NOINLINE parse0 ;
#else
: parse NOINLINE parse3 ;
#endif

: count dup c@ swap 1+ ;

: *
	>t
	0
	begin
		\ 65 emit
		over +

		t1- t@ 1- 0<
	until

	t> drop
	nip
	\ 10 emit
	;

variable outnum
: atoi
	0 outnum !
	swap >t
	begin
		dbg
		\ 84 emit
		dup
		c@ 48 -
		outnum @ 10 *
		+
		outnum !
		1+
		\ t@ 48 + emit
		t1-
		
		t@ dbg 0=

	until
	t> drop
	outnum @
	;

0xDEADBEEF

( 
12 10 *
dbg bye ENDPARSE
)

( 
dbg
key emit
dbg
bye
ENDPARSE
)

parse

2dup
type

atoi

0 dbg drop

\ 0 dbg
bye
( 
variable S0
sp@ S0 !
)


\ 12 16 +
\ 0 dbg drop

\ 5 cells u.
\ 123 u.
\  bye ENDPARSE
\ 123 10 divmod
\ bye ENDPARSE
( 
666
?key
0 dbg
)

\ HERE @ u.
( 
S0 @ .
key
sp@ 4 negate and
dbg bye
)
( 
HERE 12 , HERE
0 dbg
HERE @
)

\ HERE @ dup

( 
\ varinit EEE FORTH_END
variable EEE
HERE @ EEE !
1 ,  2 c,  3 , 4 c, 5 c,

16 EEE @ writestdout
bye
)
