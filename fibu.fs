: fib ( n1 -- n2 )
    dup 2 < if
	drop 1
    else
	dup
	1- recurse
	swap 2 - recurse
	+
    then ;

40 fib
u. cr bye
