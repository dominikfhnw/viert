( 
	# I'm also a bash script
	DEBUG=1 FULL=1 RUN= DIS=1 SOURCE=$0 bash viert3.asm -DWORD_ALIGN=1
	kill $$ # the forth comment counts as a subshell, so this is the easiest way to exit
)

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
	8
	+
	@
	not 1 + + \ -
	;

: case
	i swap divmod drop
	if
		drop \ get rid of string
	else
		sp@ 4 emitx \ print string
		1 + \ increase match counter
	then
;

: default
	if \ do nothing if match counter == 0
	else
		i u. \ print i
	then
;

MAIN
20 doloop1
	'Fizz' 3 case
	'Buzz' 5 case
	default
	10 emit
endloop1

SYS_exit
syscall3

