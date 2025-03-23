:? -
	not 1 + +
	;

: emit4b
	sp@
	4
;NORETURN
: emitx
	swap
	1
	4
	syscall3
	drop
	drop
	;

: emit
	sp@
	1
	emitx
	;

: u.
	10 divmod

	sp@ @ \ dup
	unless
		drop
	else
		u.
	then

	'0' + emit
	;

: c
	21
	rp@
	CELL_SIZE
	+
	@
	- ;


MAIN

20 doloop1
	0
( 
	c 3 mod 0= if 1+ string `Fizz` puts then
	c 5 mod 0= if 1+ string `Buzz` puts then
( )
( 
	c 3 divmod drop 0= if 1 + 'Fizz' emit4b then
	c 5 divmod drop 0= if 1 + 'Buzz' emit4b then
( )

	c 3 divmod drop unless 'Fizz' emit4b 1 + then
	c 5 divmod drop unless 'Buzz' emit4b 1 + then
	+ unless c u. then
	10 emit
endloop1

SYS_exit
syscall3
