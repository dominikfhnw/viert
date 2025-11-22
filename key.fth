\ : varg i rsdrop ;
\ : 3pick pos3 @ ;
variable agg
variable foo
: xsyscall3_noret xsyscall3 drop ;

( 
\ : xbye SYS_exit xsyscall3 ;
: -1	dup dup not nand ;
: 0	-1 not ;
: 1	-1 2* not ;
: 2	1 2* ;
\ : 3	1 dup 2* + ;
: 3	2 1+ ;
: 4	2 2* ;
: 5	4 1+ ;
: 6	3 2* ;
: 7	6 1+ ;
: 9	8 1+ ;
: 10	5 2* ;
: 11	5 2* ;
: 12	6 2* ;
: 13	12 1+ ;
: 14	7 2* ;


: 8	   4 2* ;
: 16	   8 2* ;
: 32	  16 2* ;
: 64	  32 2* ;
: 128	  64 2* ;
: 256	 128 2* ;
: 512	 256 2* ;
: 1024	 512 2* ;
: 2048	1024 2* ;
: 4096	2048 2* ;
: 8192	4096 2* ;
\ : xfalse
)

\ key
\ dup u.
\ 1 2 3 dbg 2dupswap dbg bye

\ : varg dbg ;

agg
u.
bye

( 
1 2 3 dbg swap dbg
bye

1 2 +
u.
)
( 
foo .
foo @ .
12 foo !
foo @ .
)
( 
bye
)



