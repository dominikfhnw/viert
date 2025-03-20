\ %define f_exit f_bye
\ %define f_0 f_false

:? dup
	sp@
	@
	;

:? not
	dup
	nand
	;

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

: negate
	not
	inc
	;

:? minus
	negate
	+
	;

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

: emit
	sp@
	1
	puts
	drop
	;

: 0eq
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

: space
	32
	emit
	;

: udot
	10
	divmod

	dup
	if
		udot
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
	1
	BITM1
	bshift
	;

: dot
	dup
	signbit
	and

	if
		'-'
		emit
		negate
	then
	udot
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
	udot
	nl

	fib
	;

: i
	rp@
	CELL_SIZE
	+
	@
	;

: isdiv
	over
	swap
	mod
	if
		false
	else
		true
	then
	;


MAIN
string "foobar"
puts
nl
bye
