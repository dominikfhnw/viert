\ "hello, world" example for sectorforth, a 512-byte, bootable x86 Forth.
\ Copyright (c) 2020 Cesar Blum
\ Distributed under the MIT license. See LICENSE for details.

: dup ( x -- x x ) sp@ @ ;

\ make some numbers
\ : -1 ( x -- x -1 ) dup dup nand dup dup nand nand ;
\ : 0 -1 dup nand ;
\ : 1 -1 dup + dup nand ;
\ : 2 1 1 + ;
\ : 4 2 2 + ;
\ : 6 2 4 + ;

\ logic and arithmetic operators
: invert ( x -- !x ) dup nand ;
: and ( x y -- x&y ) nand invert ;
: negate ( x -- -x ) invert 1 + ;
: - ( x y -- x-y ) negate + ;

: 0=
if
	0
else
	-1
then ;

\ equality checks
: = ( x y -- flag ) - 0= ;
: <> ( x y -- flag ) = invert ;

\ stack manipulation words
: fdrop ( x y -- x ) dup - + ;
: fover ( x y -- x y x ) sp@ 2 + @ ;
: fswap ( x y -- y x ) over over sp@ 6 + ! sp@ 2 + ! ;
: nip ( x y -- y ) swap drop ;
: 2dup ( x y -- x y x y ) over over ;
: 2drop ( x y -- ) drop drop ;

\ more logic
: or ( x y -- x|y ) invert swap invert and invert ;


\ unconditional branch
: fbranch ( r:addr -- r:addr+offset ) rp@ @ dup @ + rp@ ! ;

\ conditional branch when top of stack is 0
: fzbranch ( r:addr -- r:addr | r:addr+offset)
    0= rp@ @ @ 2 - and rp@ @ + 2 + rp@ ! ;

\ push/pop return stack
: >rexit ( addr r:addr0 -- r:addr )
    rp@ ! ;                 \ override return address with original return
                            \ address from >r
: >r ( x -- r:x)
    rp@ @                   \ get current return address
    swap rp@ !              \ replace top of return stack with value
    >rexit ;                \ push new address to return stack

\ get do...loop index
: i ( -- index ) rp@ 4 + @ ;



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

: emit sp@ 1 puts drop ;
: cr 10 emit ;
: space 32 emit ;

: mod divmod swap drop ;

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

: dot
        dup
        \ signbit
	-9223372036854775808
        and

        if
                '-'
                emit
                negate
        then
        udot
        space
        ;


: fizzbuzz ( x -- )
    cr 1 + 1 do
        i 3 mod 0= dup if string "Fizz" puts then
        i 5 mod 0= dup if string "Buzz" puts then
        or invert if i . then
        cr
    loop ;


MAIN
fizzbuzz
bye
