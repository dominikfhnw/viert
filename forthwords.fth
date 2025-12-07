:? dup
	sp@
	@
	;

:? not
	dup
	nand
	;

:? invert not ;

:? over
	sp@
	CELL_SIZE*2
	+
	!
	;

:? and
	nand
	not
	;

\ :? or ( x y -- x|y ) invert swap invert and invert ;
:? or ( x y -- x|y ) not swap not nand ;
:? nor ( x y -- x|y ) or not ;

\ :? true
\	\ lit saves us a lot of space overall, but this was an interesting
\	\ exercise nonetheless
\	dup
\	dup
\	not
\	nand
\	;

:? swap
	\ : swap ( x y -- y x ) over over sp@ 6 + ! sp@ 2 + ! ;
	\ TODO: can probably be made smaller
	over
	over
	sp@
	CELL_SIZE*3
	+
	!
	sp@
	CELL_SIZE
	+
	!
	;

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

:? branch2
	rp@
	@
	+
	rp@
	!
	;

:? drop
	dup
	-
	+
	;


: 2dup
	over
	over
	;

: 2drop
	drop
	drop
	;

: mod
	divmod
	drop
	;

: div
	divmod
	swap
	drop
	;

:? bye
	SYS_exit
	syscall3
	;

: puts
	swap
	STDOUT
	SYS_write
	syscall3
	drop
	;

\ : miau string "miau" puts ;

: emit
	sp@
	1
	puts
	drop
	;

: emit4
	sp@
	4
	puts
	drop
	;

: 0=
	if
		false
	else
		true
	then
	;

: nl
	10
	emit
	;

: cr nl ;

: space
	32
	emit
	;

: u.
	10
	divmod

	dup
	if
		u.
	else
		drop
	then

	'0'
	+
	emit
	;

: bshift
	1
	swap
	doloop1
		dup
		plus
	endloop1
	;

: signbit
	BITM1
	bshift
	;

: .
	dup
	signbit
	and

	if
		'-'
		emit
		negate
	then
	u.
	space
	;

: isnegative
	dup
	signbit
	and
	;

: fib
	2dup
	+

	isnegative
	if
		EXIT
	then

	dup
	u.
	nl

	fib
	;

: ix
	rp@
	CELL_SIZE
	+
	@
	;

\ : fizzbuzz ( x -- )
\     nl 1 + 1 do
\         i 3 mod 0= dup if string "Fizz" puts then
\         i 5 mod 0= dup if string "Buzz" puts then
\         or invert if i . then
\         cr
\     loop ;

: c
	21
	rp@
	CELL_SIZE
	+
	@
	- ;


: .d
	dup .
;


: mod2
	divmod
	drop
	\ drop
	.d
	;

\ : 0=
\ 	if
\ 		false
\ 	else
\ 		true
\ 	then
\ 	;

: fiz2
20 doloop1
\	c 3 mod2 0= dup if string `F\40` puts else string `\40\40` puts then
	false
	c 3 mod 0= if 1+ string `Fizz` puts then
	c 5 mod 0= if 1+ string `Buzz` puts then
\	c 5 mod2 if string `\40\40` puts else string `B\40` puts then
\ 	c 3 isdiv dup if
\ 		string "Fizz"
\ 		puts
\ 	then
\ 
\ 	c 5 isdiv dup if
\ 		string "Buzz"
\ 		puts
\ 	then

	+ 0= if c . then
	nl
endloop1 ;

MAIN
\ fiz2
string "fizz"
puts
bye
