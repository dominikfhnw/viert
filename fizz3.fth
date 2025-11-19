\		# I'm also a bash script
\ / 2>&-;	DEBUG= RUN= DIS=1 SOURCE=$0 ./viert.sh -DWORD_ALIGN=1 -DWORDSET=2; exit $?

: u.
	10 divmod

	sp@ @			\ dup
	if
		u.
	else
		drop
	endif

	'0' +
	;CONTINUE


: emit
	1
	;CONTINUE

: emitx
	sp@
	CELL_SIZE*1 +
	1
	4
	syscall3
	drop
	drop
	;

: case
	divmod drop
	if
		drop		\ get rid of string
	else
		4 emitx	\ print string
		1 +		\ increase match counter
	endif
;

MAIN
begin
	rsinci 20 not +
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

		
again

