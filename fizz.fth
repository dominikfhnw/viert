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

: i
	21
	rp@
	CELL_SIZE
	+
	@
	not 1 + + \ -
	;

: fl sp@ 4 emitx 1 + ;


MAIN
20 doloop1
( 
	c 3 mod 0= if 1+ string `Fizz` puts then
	c 5 mod 0= if 1+ string `Buzz` puts then
( )
( 
	c 3 divmod drop 0= if 1 + 'Fizz' emit4 then
	c 5 divmod drop 0= if 1 + 'Buzz' emit4 then
( )

	i 3 divmod drop unless 'Fizz' fl then
	i 5 divmod drop unless 'Buzz' fl then
	unless i u. then
	10 emit
endloop1

SYS_exit
syscall3
