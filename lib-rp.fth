:? dup sp@ @ ;
:? not dup nand ;
: invert not ;
: and nand not ;
: true dup dup not nand ;

:? drop dup not nand and ;

\ : false 0 ;
: false true not ;
: true2 false not ;

\ old PLOOS stuff was here

:? 1+ 1 + ;
: 2+ 1+ 1+ ;
: 4+ 2+ 2+ ;
: CELL+ 4+ ;
: 8+ 4+ 4+ ;
: 12+ 8+ 4+ ;
: inc 1+ ;
\ : dec true + ;
: dec not inc not ;
: 1-  dec ;

: negate not inc ;

\ :? rp@ rpsp@ drop CELL+ ;
:? rp@ rpsp@ drop CELL+ ;
: rx @ rsdrop ;	\ XXX only works when inlined?
: varhelper rp@ rx ;
variable o1
variable o2
variable o3
:? swap
	\ : swap ( x y -- y x ) over over sp@ 6 + ! sp@ 2 + ! ;
	\ TODO: can probably be made smaller
	( \ w/o variables
	2dup
	pos3 !
	pos1 !
	)
	o1 ! o2 !
	o1 @ o2 @

	;




:? absbranch rp@ ! ;
\ :? rpsp@ rp@ CELL_SIZE + sp@ ;


\ : rp@dup rpsp@ @ ;
\ rp@dup rp@ dup ;
: rflip ( r:ret1 r:ret2 val retaddr1 ret1 -- r:val r:ret1 ) 
	rp@ !
	( r:ret1 r:ret1 val retaddr1 )
	\ store new value on retstack
	!
	( r:val r:ret1 )
	;

:? >r ( r:ret1 val -- r:val ) \ also known as ">r"
	rp@ dup @
	\ next two words can be here or in rflip. TODO rewrite
	rflip
	;
: rspush >r ;


:? r@ rp@ CELL_SIZE*2 + @ ;
\ : r> rp@ CELL_SIZE*0 + @  rsdrop ; 
\ : r> rp@ rsdrop ;

: over1 o1 ! o2 ! dup o3 ! o2 @ o1 @ o3 @ ;

\ : 2dupswap dup pos2 @ ;
: 2dupswap dup over1 ;
\ : 2dupswap 2dup swap ; 
\ : 2dupswap r> rp@ 4 + @ dup ;
( 
: pos1 sp@ CELL_SIZE*1 + ;
:? over pos1 @ ;

: 2dup
	over
	over
	;
)

\ : xor 2dup not nan/ -rot 
\ : notnand
: xor1 not nand ;
\ : xor2 swap not nand ;
\ : wxor 2dup xor1 -rot xor2 nand ;
\ : xxor 2dup xor1 >r swap r> swap >r swap r> xor1 nand ;

\ : yxor 2dupswap xor1 -rot xor1 nand ;
: xor 2dupswap xor1 dbg >r xor1 rp@ rx dbg nand ;

\ : 0=   if false else true  then ;

:? x+
	begin
		2dupswap and 2* >r  \ carry
		xor rp@ rx          \ carryless add
		dup 0=
		\ dbg
	until
	drop
	;

\ PLOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOS 
:? 2* dup + ;
( requires negate, which requires plus )
: 0= dup 0< swap negate 0< or ;


:? xx+
	begin

	until
	;


:? - negate + ;

\ :? drop dup - + ;
( a b	- dup
  a b b - -
  a 0   - +
  a
)

: pos1 sp@ CELL_SIZE*1 + ;
:? over pos1 @ ;

: 2dup
	over
	over
	;
: 2drop drop drop ;

: pos2 sp@ CELL_SIZE*2 + ;
: pos3 sp@ CELL_SIZE*3 + ;
\ PLOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOS 


:? i rp@ CELL_SIZE*1 + @ ;
:? j rp@ CELL_SIZE*2 + @ ;
: r@ i ;
: r> r@ rsdrop ;
\ :? r@ rp@ CELL_SIZE*1 + @ ;
\ : r@ rp@ CELL_SIZE*1 + @ ;


: rot >r swap r> swap ;
: -rot rot rot ;


\ : LIT RP@ @ 2 ( 4 ) + DUP RP@ ! @ ;
\ : xlit32 rp@ @ 1 + dbg dup rp@ ! @ ;
\ : xlit32 rp@ @ dup CELL_SIZE + dbg rp@ dbg ! @ dbg ;
: xlit32 rp@ @ dup 4+ dbg rp@ dbg ! @ dbg ;
\ : xlit32 lit32 ;
\ :? 0< 0x80000000 and ;
\ :? 0< 0x7fffffff not and ;
:? 0< 0x80000000 and ;
:? < - 0< ;
\ : 0= dup 0< swap negate 0< or ;
: x0<> x0= not ;
\ :? absbranch rp@ ! ;
: x3branch
	rp@ @	\ fetch return address
\ 	dup @	\ fetch content at the return address, i.e. the next cell in the caller
	@	\ fetch content at the return address, i.e. the next cell in the caller
	rp@ !	\ write it back
	;
: xbranch
	rp@ @	\ fetch return address
	\ dbg
	dup @	\ fetch content at the return address, i.e. the next cell in the caller
	CELL_SIZE -
	\ dbg
	+	\ add that value to our current return address
	CELL_SIZE +
	\ rp@ dbg !	\ write it back
	rp@ !	\ write it back
	;
: xzbranch
	\ dbg
	x0=		\ is the cell zero? yes => -1, no => 0
	rp@ @		\ fetch return address
	@		\ fetch content at the return address, i.e. the next cell in the caller
	CELL_SIZE -	\ subtract a cell size
	\ dbg

	and		\ mask origin address with the truth value. I.e., 0 if false, otherwise lit
	\ dbg		\ This is now the same as the two words "lit" "<number>"
	rp@ @
	+		\ fetch return address again, offset it by lit
	CELL_SIZE +	\ add CELL_SIZE??
	\ rp@ dbg !	\ write value as our return address
	rp@ !	\ write value as our return address
	;

\ : BRANCH RP@ @ DUP @ + 2 + RP@ ! ;
\ : ?BRANCH 0= RP@ @ @ AND RP@ @ + 2 + RP@ ! ;
\ : DUP SP@ @ ;
\ : -1 ( x -- x 0 ) DUP DUP NAND DUP DUP NAND NAND ;
\ : 1 -1 DUP + DUP NAND ;
\ : 2 1 DUP + ;
\ : 4 2 DUP + ; for 4 bytes/cell Forth

\ HAVE: 0<
\ WANT: 0= (or 0<>)

\ -2 -2 0<
\ -2 0xFFFFFFF  -> swap
\ 0xFFFFFFFF -2 -> negate
\ 0xFFFFFFFF 2  -> 0<
\ 0xFFFFFFFF 0  -> or
\ 0xFFFFFFFF

\ 3 3 0<
\ 3 0  -> swap
\ 0 3 -> negate
\ 0 -3 -> 0<
\ 0 0xFFFFFFFF -> or
\ 0xFFFFFFF

\ 0 0 0<
\ 0 0  -> swap
\ 0 0 -> negate
\ 0 0 -> 0<
\ 0 0 -> or
\ 0


\ rot   ( a b c -- b c a )
\ -rot  ( a b c -- c a b ) rot rot ;


: or ( x y -- x|y ) not swap not nand ;
\ :? 0< 0x80000000 and ;

:? dup0< dup 0< ;

: rsinc
	rp@ CELL_SIZE + dup
	( addr addr )
	@
	( addr val )
	inc
	( addr val+1 )
	swap
	( val+1 addr )
	!
	;

: rsinci rsinc i ;
: i1+ rsinci ;
:? xdivmod
	( num div )
	swap
	( div num )

	0 rspush

	begin
		over
		( div num div )
		-
		dup0<
		if
			+
			r>
			EXIT
		then
		rsinc
	again
	;NORETURN

:? modfast
	( num div )
	swap
	( div num )

	0 rspush

	begin
		over
		( div num div )
		-
		dup0<
		if
			r>
			EXIT
		then
		rsinc
	again
	;NORETURN


:? divfast
	( num div )
	swap
	( div num )

	0 rspush

	begin
		over
		( div num div )
		-
		dup0<
		if
			+
			rsdrop
			EXIT
		then
		rsinc
	again
	;NORETURN

: 3pick pos3 @ ;
:? xsyscall3
	0 3pick 3pick 3pick
	syscall7
;

:? syscall3_noret syscall3 drop ;

 : u.
 	10 divmod
 
 	dup
 	if
 		u.
 	else
 		drop
 	then
 
 	'0' +
 	;CONTINUE
 
 : emit
 	1
 	;CONTINUE
 
 : emitn
 	sp@
 	CELL_SIZE*1
 	+
 	STDOUT
 	SYS_write
 	syscall3_noret
 	drop
 	;

\ : emitn
\ 	sp@
\ 	CELL_SIZE*1
\ 	+
\ 	STDOUT
\ 	SYS_write
\ 	syscall3_noret
\ 	drop
\ 	;
\ 
\ : emit
\ 	1
\ 	emitn
\ 	;
\ 
\ : u.
\ 	10 divmod
\ 
\ 	dup
\ 	if
\ 		u.
\ 	else
\ 		drop
\ 	then
\ 
\ 	'0' +
\ 	emit
\ 	;


: emit4 4 emitn ;

: key
	0	\ key gets saved here
 	1
 	sp@ CELL_SIZE*1 +
 	STDIN
 	SYS_read
 	syscall3_noret
	;

: mod divmod drop ;

: writestdout STDOUT SYS_write syscall3_noret ;

: nl 10 emit ;
: cr nl ;
: bl 32 ;
: space bl emit ;

: .
	dup0<
	if
		'-'
		emit
		negate
	then
	u. space
	;


: bye SYS_exit syscall3_noret ; 
: xbye 1 syscall7 ;
: xsleep 0 swap sp@ 0 swap 162 syscall3_noret drop ;
: sleep 0 over 0 pos1 162 syscall3_noret 2drop ;


\ : 0<>  if true  else false then ;
:? 0<> 0= not ;
: =  - 0=  ;
: <> = not ;
: <>2 - 0<> ;
\ : <> - 0<> ;
\ : <> - ;
\ : = <> not ;
: up i = ;
\ so woah... if equal, then x + (not x) will be 0xFF.... == -1 == true
\ because... (not x) is the inverse of x... and if no overlap, then "+" is equal to "or"
\ : = not + ;
\ : <> invert + invert ;
