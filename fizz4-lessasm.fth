( 
	# I'm also a bash script
	#DEBUG=1 FULL=1 RUN= DIS=1 SOURCE=$0 bash viert3.asm -DWORD_ALIGN=1
	#DEBUG= FULL= RUN= DIS=1 SOURCE=$0 bash viert3.asm -DWORD_ALIGN=1
	RUN= DIS=1 SOURCE=$0 bash viert3.asm -DWORD_ALIGN=1
	kill $$ # the forth comment counts as a subshell, so this is the easiest way to exit
)

:? dup
	sp@
	@
	;

(
\ ALIAS -1
:? true
	\ ( equals -1 )
	\ lit saves us a lot of space overall, but this was an interesting
	\ exercise nonetheless
	dup
	dup
	not
	nand
	;

\ ALIAS false
:? 0
	\ ( equals 0 )
	true not ;

:? 1
	true true + not
	;


\ numbers needed: 0 1 4 8 12 10 32 2147483648
:  2 1 1 + ;
:  3 1 2 + ;
:  4 2 2 + ;
:  5 4 1 + ;
:  8 4 4 + ;
: 10 8 2 + ;
: 12 8 4 + ;
: 16 8 8 + ;
: 32 16 16 + ;

)

: pos3
	sp@ CELL_SIZE*3 + ;
: pos2
	sp@ CELL_SIZE*2 + ;
: pos1
	sp@ CELL_SIZE*1 + ;
	
:x pick2
	pos2 @ ;
:x pick1 over ;
:x pick0 dup ;

:? over
	pos1
	@
	;

: 2dup
	over
	over
	;

:? swap
	\ : swap ( x y -- y x ) over over sp@ 6 + ! sp@ 2 + ! ;
	\ TODO: can probably be made smaller
	2dup
	pos3 !
	pos1 !
	;

\ :? drop2
\ 	sp@
\ 	@
\ 	not
\ 	1
\ 	+
\ 	+
\ 	+
\ 	;
\ 

:? drop
	sp@
	0
	swap	\ putting '0' first would change sp
	!
	+
	;

:? nip swap drop ;
:? and nand not ;
\ :? or ( x y -- x|y ) not swap not nand ;
\ :? nor ( x y -- x|y ) or not ;


:? bye
	SYS_exit
	syscall3
	;


: emit
	sp@
	1
;NORETURN

: emitx
	swap
	1
	4
	syscall3
	drop
	drop
	;

: emit4
	sp@ 4 emitx ;

: nl	10 emit ;

:x
space	32 emit ;

: inc	1 + ;

: negate
	not
	inc
	;

:? -
	negate
	+
	;

:? dec 1 - ;

\ :? minus2
\ 	not
\ 	1
\ 	+
\ 	+
\ 	;

: isnegative
	dup
	\ TODO not working for 64b
	\ TODO hex not supported yet
	\ 0x80000000
	2147483648
	and
	;


: incpos2
	pos2
	dup
	@
	inc
	swap
	!
	;


:? divmod
	( num div )
	over
	( num div num )
	0 pos3 !
	( 0 div num )
	\ dbg

	begin
		over
		-
		isnegative
		if
			+ swap EXIT
		then
		incpos2
	again
	;

: mod
	divmod
	drop
	;

:x div
	divmod
	swap
	drop
	;


: u.
	10 divmod

	dup
	if
		u.
	else
		drop
	then

	'0' + emit
	;

\ : bshift
\ 	1
\ 	swap
\ 	\ doloop1
\ 		dup
\ 		plus
\ 	\ endloop1
\ 	;
\ 
\ : signbit
\ 	BITM1
\ 	bshift
\ 	;


:x .
	isnegative
	if
		'-'
		emit
		negate
	then
	u.
	space
	;

\ 
\ 
\ : fib
\ 	2dup
\ 	+
\ 
\ 	isnegative
\ 	if
\ 		EXIT
\ 	then
\ 
\ 	dup
\ 	u.
\ 	nl
\ 
\ 	fib
\ 	;
\ 

: case
	mod
	if
		drop		\ get rid of string
	else
		emit4		\ print string
		inc		\ increase match counter
	endif
;

: whilelt
	-
	\ dup u.
	unless bye then
	;

\ : whilele
\	inc
\	whilelt
\	;

\ : orbye
\ 	unless bye then ;

:? rp@ rpsp@ drop CELL_SIZE + ;

:? i rp@ CELL_SIZE + @ ;

:? rsinc
	rp@ CELL_SIZE + dup @
	( addr val )
	inc
	( addr val+1 )
	swap
	( val+1 addr )
	over
	( val+1 addr val+1 )
	swap
	( val+1 val+1 addr )
	!
	( val+1 )

	;

: inext
	dec dup rp@ ! ;


:x rsinc2
	rp@ CELL_SIZE + dup @
	( addr val )
	inc
	( addr val+1 )
	swap
	( val+1 addr )
	!

	;

:? mul
	0
	( 4 5 0 )
	swap
	( 4 0 5 )
	for
		( 4 0 )
		over
		( 4 0 4 )
		+
		( 4 4*n )
		dup u. nl
	next
	nip
	( 4*n )
	;

:x mul ( n1 n2 -- res )
	over
	( n1 n2 n1 )
	begin
		over
		rsinc
		( n1 n2 n1 n2 i )
		-
		( n1 n2 n1 t )
		dup u. space
		if
			'n' emit
		else
			'F' emit
			EXIT
		then
		( n1 n2 n1 )
		\ over
		( n1 n2 n1 n2 )
		+
		( n1 n2 x )

		dup u. nl
	again
	;


MAIN
\ 23 4 divmod
\ 32 u. nl
\ bye
\ u. nl u. nl
\ bye
\ 1 2 3 dbg 
\ drop dbg
\ swap dbg
\ bye
\	rsinc dup u. space 21 - dup u. nl
\	rsinc 21 - 
\	orbye

\ for( i = 1; i <= 20; i++ )
\ i = 0: check at the end of the loop
4 5 mul
\ 0
\ ( 4 5 0 )
\ swap
\ ( 4 0 5 )
\ for
\ 	( 4 0 )
\ 	over
\ 	( 4 0 4 )
\ 	+
\ 	( 4 4*n )
\ 	dbg
\ 	dup u. nl
\ next
\ nip
\ ( 4*n )
u. nl
dbg
bye
(
begin
	rsinc

	0
	'Fizz' i 3 case
	'Buzz' i 5 case

	unless		\ do nothing if match counter != 0
		i u.	\ print i
	then
	nl		\ print newline

20 whilelt again
)
(
:? not
	dup
	nand
	;

:? invert not ;

:? and
	nand
	not
	;

\ :? or ( x y -- x|y ) invert swap invert and invert ;
\ :? or ( x y -- x|y ) not swap not nand ;
\ :? nor ( x y -- x|y ) or not ;

\ :? true
\	\ lit saves us a lot of space overall, but this was an interesting
\	\ exercise nonetheless
\	dup
\	dup
\	not
\	nand
\	;

: false
	0
	;

: true
	\ defining true as -1 allows use to just use binary "not" to invert booleans.
	\ This is much more elegant than to use 0 and 1, and then having to use
	\ "0=" for negation like in jonesforth.
	\ -1 feels more like the Forth way.
	\ This also just uses the first Peano axiom. I don't know any number except
	\ 0, and frankly I do not want to know any other numbers.
	false
	not
	;

:? dec
	\ curiously, we can define dec before inc, even though we only have "plus"
	\ and "not" as primitives.
	true
	+
	;
: 1- dec ;

: 1
	\ Ok, let's also use the successor of zero. It makes things easier.
	1
	;

: inc
	\  So this jumps wildly ahead of what started with the first Peano axiom.
	\ But truth is, performance is much better with defining increment in terms
	\ of plus than the other way around.
	1
	+
	;
: 1+ inc ;

: negate
	not
	inc
	;

:? -
	negate
	+
	;

\ :? minus2
\ 	not
\ 	1
\ 	+
\ 	+
\ 	;
\ 
\ 
\ :? minus3
\ 	dup
\ 	nand
\ 	1
\ 	+
\ 	+
\ 	;
\ 
\ :? minus4
\ 	sp@ @
\ 	nand
\ 	1
\ 	+
\ 	+
\ 	;

\ :? branch2
\	rp@
\	@
\	+
\	rp@
\	!
\	;

\ :? drop
\ 	dup
\ 	-
\ 	+
\ 	;


: 2drop
	drop
	drop
	;
: 0=
	if
		false
	else
		true
	then
	;

: cr nl ;


\ : 0=
\ 	if
\ 		false
\ 	else
\ 		true
\ 	then
\ 	;
)
