( 
	# I'm also a bash script
	#DEBUG=1 FULL=1 RUN= DIS=1 SOURCE=$0 bash viert3.asm -DWORD_ALIGN=1
	#DEBUG= FULL= RUN= DIS=1 SOURCE=$0 bash viert3.asm -DWORD_ALIGN=1
	DEBUG= RUN= DIS=1 SOURCE=$0 bash viert3.asm -DWORD_ALIGN=1
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

	sp@ @			\ dup
	if
		u.
	else
		drop
	endif

	'0' + emit
	;

: case
	divmod drop
	if
		drop		\ get rid of string
	else
		sp@ 4 emitx	\ print string
		1 +		\ increase match counter
	endif
;

MAIN
do
	rsinc 20 not +
	if
		'Fizz' i 3 case
		'Buzz' i 5 case

		if
				\ do nothing if match counter != 0
		else
			i u.	\ print i
		endif
		10 emit		\ print newline
	else
		SYS_exit
		syscall3
	endif

		
loop

