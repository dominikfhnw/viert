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
MAIN
string `hello\40world\n`
puts
bye
