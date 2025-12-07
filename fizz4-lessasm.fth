\ 		# I'm also a bash script
\ / 2>&-;	LIT8=0 RUN= DIS=1 SOURCE=$0 ./viert.sh -DWORD_ALIGN=1 "$@" -DWORDSET=4; exit $?

: 0 0 ;
: 1 1 ;
: 4 4 ;
: 10 10 ;

:? dup
	sp@
	@
	;

:? not dup nand ;

: = not + ;
: inc	1 + ;

: negate
	not
	inc
	;

:? -
	negate
	+
	;

:x true dup dup not nand ;
:? drop
	\ sp@
	\ 0
	\ swap	\ putting '0' first would change sp
	\ !
	\ +
	dup
	- +
	;

: pos1 sp@ CELL_SIZE*1 + ;

:? over
	pos1
	@
	;

:? rp@ rpsp@ drop CELL_SIZE + ;

\ NOINLINE
: rflip ( r:ret1 r:ret2 val retaddr1 ret1 -- r:val r:ret1 ) 
	rp@ !
	( r:ret1 r:ret1 val retaddr1 )
	\ store new value on retstack
	!
	( r:val r:ret1 )
	;

\ NOINLINE
:? rspush ( r:ret1 val -- r:val ) \ also known as ">r"
	\ ret of rspush
	rp@ 
	\ next two words can be here or in rflip
	dup
	@
	rflip
	;

:? branch
	rp@ !
	;

:? i CELL_SIZE*1 rp@ + @ ;
:x j CELL_SIZE*2 rp@ + @ ;

\ :? i rpsp@ drop @ ;
\ :? i rp@ @ ;


\ XXX OLD XPICK LOC

: pos2 sp@ CELL_SIZE*2 + ;
\ : pick2 pos2 @ ;
\ : pick1 over ;
\ : pick0 dup ;


: 2dup
	over
	over
	;

: pos3 sp@ CELL_SIZE*3 + ;

:? swap
	\ : swap ( x y -- y x ) over over sp@ 6 + ! sp@ 2 + ! ;
	\ TODO: can probably be made smaller
	2dup
	pos3 !
	pos1 !
	;

:x rot rspush swap i rsdrop swap ;
:x -rot rot rot ;

\ :? or ( x y -- x|y ) not swap not nand ;
: and nand not ;
:x or ( x y -- x|y ) not swap not nand ;
:? 0<
	0x80000000
	and
	;

:x dup0<
	dup
	0<
	;



\ :? nor ( x y -- x|y ) or not ;


:x xor2
	( x y )
	2dup
	\ 2dup . . nl
	( x y x y )
	nand
	\ dup . nl
	( x y XnandY )
	rspush
	( x y XnandY y )
	
	( XnandY x y )
	\ 2dup . . nl
	or
	\ dup . nl
	( XnandY XorY )
	\ 2dup . . nl
	i rsdrop
	and
	( XOR )
	;


:x xor
	( x y )
	2dup
	\ 2dup . . nl
	( x y x y )
	nand
	\ dup . nl
	( x y XnandY )
	-rot
	( XnandY x y )
	\ 2dup . . nl
	or
	\ dup . nl
	( XnandY XorY )
	\ 2dup . . nl
	and
	( XOR )
	;


:x nip swap drop ;

:x 0< dup0< nip ;

:x mul
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
		\ dup u. nl
	next
	nip
	( 4*n )
	;

:x pick
	inc
	CELL_SIZE
	mul
	sp@
	+
	@
	;

:x xpick
	CELL_SIZE*2
	over
	for
		CELL_SIZE +
	next
	sp@
	+
	@
	;


:? bye
	SYS_exit
	syscall3_noret
	;

:? incpos2
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
		dup 0<
		if
			+ swap EXIT
		then
		incpos2
	again
	;


: u.
	10 divmod

	dup
	if
		u.
	else
		drop
	then

	'0' +
	;CONTINUE


: emit
	sp@
	1
	;CONTINUE

: emitx
	swap
	1
	4
	syscall3_noret
	drop
	drop
	;

\ : puts 0 emitx ;

: emit4
	sp@ 4 emitx ;

: nl	10 emit ;


\ :? minus2
\ 	not
\ 	1
\ 	+
\ 	+
\ 	;


:x rsinci
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


: rsinc
	rp@ CELL_SIZE + dup 
	( addr addr )
	@
	( addr val )
	inc
	( addr val+1 )
	swap
	( val+1 addr )
	!
	;

:x rsinci rsinc i ;

:x divmod
	( num div )
	swap
	( div num )

	0 rspush

	begin
		over
		( div num div )
 		-
		dup0<
		if
			+ 
			i
			rsdrop
			EXIT
		then
		rsinc
	again
	;NORETURN

: mod
	divmod
	drop
	;

:x div
	divmod
	swap
	drop
	;


(
: space	32 emit ;
: .
	dup0<
	if
		'-'
		emit
		negate
	then
	u.
	space
	;
)



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
	then
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

:x xpick
	CELL_SIZE*2
	over
	for
		CELL_SIZE +
	next
	dbg
	sp@
	+
	@
	;

:x sleep
	0
	swap
	sp@
	0
	swap
	162
	syscall3
	;

:x hidden
	'SECR' emit4 nl
	;

:x .
	dup0<

	if
	'-'
	emit
	negate
	then
	u.
	space
	;

:x 0= dup not nand ;
:x 0<> 0= not ;

:x x0<> 0 <> ;
:x x0= dup not nand ;
:x x= not + ;

(
: true dup dup not nand ;
: false 0 ;
: true2 false not ;
: true3 -1 ;

: 0= false = ;
: <> = not ;
: 0<> 0= not ;
: y0<> true + not ;
)
MAIN
(
1 0= dbg
0 0= dbg
\ 1 y0= dbg
\ 1 0<> dbg
nl bye
)

\ 12 for i . next
\ 1 21 swapdo i . loop

\ bye

\ 'SECR' emit4 nl
\ A_hidden
\ absbranch
(
7 6 5 4 3 2 20 int3 syscall7
)
\ 0 u. nl

\ for( i = 1; i <= 20; i++ )
\ i = 0: check at the end of the loop
\ 4 5 mul
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
\ u. nl
\ dbg
\ bye

\ 1 sleep
(
666 1 2 3 over
u. space
u. space
u. space
u. space
u.
nl
bye
)



begin
	rsinc

	0
	'Fizz' i 3 case
	'Buzz' i 5 case

	unless		\ do nothing if match counter != 0
		i u.	\ print i
	then
	nl		\ print newline

i 16 whilelt again




\ \ numbers needed: 0 1 4 8 12 10 32 2147483648
\ :  2 1 1 + ;
\ :  3 1 2 + ;
\ :  4 2 2 + ;
\ :  5 4 1 + ;
\ :  8 4 4 + ;
\ : 10 8 2 + ;
\ : 12 8 4 + ;
\ : 16 8 8 + ;
\ : 32 16 16 + ;


