\ This file gets preprocessed by cpp 

:? dup sp@ @ ;
:? not dup nand ;
: invert not ;
: and nand not ;
: droptrue  dup not nand ;
: dropfalse dup not and ;
:? drop droptrue and ;

#if XLIT
: true dup droptrue ;
: false true not ;
#else
: false 0 ;
: true false not ;
#endif

#if PLUS
	asm "+"
	:? 2* dup + ;
	#if XLIT
		: 1 true dup + not ;
		: 2 1 2* ;
		: 4 2 2* ;
	#endif
	:? 1+ 1 + ;
	: 2+ 2 + ;
	: 4+ 4 + ;
#else
	: 2+ 1+ 1+ ;
	: 4+ 2+ 2+ ;
#endif

: CELL+ 4+ ;
:? rp@ rpsp@ drop CELL+ ;
: xlit32 rp@ @ dup CELL+ rp@ ! @ ;
: xlit8  rp@ @ dup 1+    rp@ ! @ 255 and ;

#if RWMEM && !FULL
	: rwx 7 65536 dup 125 syscall3 drop ;
	rwx
#else
	: rwx ;
#endif

: varhelper rp@ @ rsdrop ;
variable o1
variable o2
variable o3
:? swap
	\ w/o variables
	\ 2dup
	\ pos3 !
	\ pos1 !
	
	\ w/ variables
	o1 ! o2 !
	o1 @ o2 @
	;

: imply not nand ;
: xor
	swap
	imply

	o2 @ o1 @
	imply

	nand
	;

: 8+ 4+ 4+ ;
: CELL*2+ CELL+ CELL+ ;
: 12+ 8+ 4+ ;
: inc 1+ ;
\ : dec true + ;
: dec not inc not ;
: 1-  dec ;

: pos1 sp@ CELL+ ;
: pos3 sp@ CELL*2+ CELL+ ;
:? over pos1 @ ;

#include "demit.fth"

: negate not 1+ ;


: 2dup
	over
	over
	;

\ : swap ( x y -- y x ) over over sp@ 6 + ! sp@ 2 + ! ;



: nip ( a b -- b ) swap drop ;


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
	\ rp@ dup @
	rpsp@ @ @

	\ next two words can be here or in rflip. TODO rewrite
	rflip
	;
: rspush >r ;


\ :? r@ rp@ CELL_SIZE*2 + @ ;
\ : r> rp@ CELL_SIZE*0 + @  rsdrop ; 
\ : r> rp@ rsdrop ;

\ : 2pick o1 ! o2 ! dup o3 ! o2 @ o1 @ o3 @ ;
: 2pick sp@ CELL*2+ @ ;

\ : 2dupswap dup pos2 @ ;
: 2dupswap dup 2pick ;
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
\ : xor2 swap not nand ;
\ : wxor 2dup imply -rot xor2 nand ;
\ : xxor 2dup imply >r swap r> swap >r swap r> imply nand ;

\ : yxor 2dupswap imply -rot imply nand ;
\ : xor 2dupswap imply dbg >r imply rp@ @ rsdrop dbg nand ;

\ : xor 2dupswap imply >r imply rp@ @ rsdrop nand ;
\ : xor		 ( a b )
\   2dupswap	 ( a b b a )
\   imply	 ( a b x1 ) 
\   >r		 ( a b R:x1 )
\   imply	 ( x2 )
\   rp@ @ rsdrop ( x2 x1 )
\   nand	 ( xor )
\ ;

: rsinc
	rp@ CELL+ dup
	( addr addr )
	@
	( addr val )
	inc
	( addr val+1 )
	swap
	( val+1 addr )
	!
	;
: rsdec
	rp@ CELL+ dup
	( addr addr )
	@
	( addr val )
	dec
	( addr val-1 )
	swap
	( val-1 addr )
	!
	;


:? r@ rp@ CELL+ @ ;

 
\ : goo dup 2* or ;
\ : ga0 goo goo ;
\ : ga1 ga0 ga0 ;
\ : ga2 ga1 ga1 ;
\ : ga3 ga2 ga2 ;
\ : maxb ga3 ga3 ;

\ : 0=1 0 = ;
\ : 0=2 dup 0< swap negate 0< or not ;
\ : 0=3 if false else true then ;
\ : 0=4 0 dbg xor not ;
\ 
\ : goo= NOINLINE dup 0=2 over dbg 0=4 dbg and not maxb not nip ;
\ \ https://en.wikipedia.org/wiki/Two%27s_complement#Working_from_LSB_towards_MSB
\ \ looks like the first bit set (from LSB) is the same in the number and its two's complement
\ : goo2 NOINLINE 
\ 	dup maxb swap negate maxb or dup 0 xor  or not ;
\ 

		\ XXX TODO XXX
		\ This is the fatal achilles heel of doing 0< with nand:
		\ we don't get clean Forth booleans back, so we have to lean
		\ on zbranch to do the right thing.
		\ Which of course won't work if we want to implement zbranch in pure Forth.

\ This will work with a weak zbranch. But needs an if/zbranch
\ : = ( w w -- t ) xor if false EXIT then true ;	\ from eForth
\ : =  ( w w -- t ) xor if false else true  then ;	\ from eForth
\ might be smaller/faster:
\ : = ( w w -- t ) xor true swap if not then ;	\ from eForth


\ From Hacker's Delight, "Manipulating Rightmost Bits", algorithm 7
\ converts a non-0 integer to... something with quite a bit of 1 bits
\ : hdr2 NOINLINE dup 1- not or ;
\ : hdr2 dup 1- not not swap imply ;
\ hdr  NOINLINE dup not swap 1- nand ;
\ hdr4 NOINLINE dup not swap 1- nand ;
: hdr  NOINLINE dup 1-  swap imply ;
\ hdr5 NOINLINE dup 1-  swap not nand ;


\ This version is weak
:x 0< 0x80000000 and ;

: or ( x y -- x|y ) not swap imply ;
 
\ : = ( w w -- t ) xor if false EXIT then true ;	\ from eForth
#if MOO
:x 0<> dup 0< swap negate 0< or ;
:x 0= 0<> not ;
: 0= dup 0< not swap negate 0< not and ;
: 0<> 0= not ;
#else
: 0= if false else true then ;
: 0<> 0= not ;
#endif
: = - 0= ;
: <> = not ;

: rot >r swap r@ rsdrop swap ;
: -rot rot rot ;


\ absolute branch
: xbranch
	rp@ @	\ fetch return address
	@	\ fetch content at the return address, i.e. the next cell in the caller
	rp@ !	\ write it back
	;

\ absolute zbranch
: xzbranch
	0= 
	dup not \ our copy of negated truthiness
	rp@ @	\ fetch return address
	\ dup
	CELL+	\ we want to skip over the address if false
	nand \ negated truthiness plus our skip address, negated
	dbg
	swap


	rp@ @ @	\ fetch content at the return address, i.e. the next cell in the caller
	dbg	\ 2 values: truthiness, addr1
	nand
	nand
	dbg
	rp@ !	\ write it back
	;

\ absolute zbranch
:x xzbranch
	0= 
	dup not \ our copy of negated truthiness
	rp@ @	\ fetch return address
	\ dup
	CELL+	\ we want to skip over the address if false
	and \ negated truthiness plus our skip address
	dbg
	swap


	rp@ @ @	\ fetch content at the return address, i.e. the next cell in the caller
	dbg	\ 2 values: truthiness, addr1
	and
	or	\ maybe some DeMorgan to simplify it?
	dbg
	rp@ !	\ write it back
	;


\ absolute zbranch
:x xzbranch
	0= 
	dup not \ our copy of negated truthiness
	rp@ @	\ fetch return address
	\ dup
	CELL+	\ we want to skip over the address if false
	and \ negated truthiness plus our skip address
	dbg
	o1 !


	rp@ @ @	\ fetch content at the return address, i.e. the next cell in the caller
	dbg	\ 2 values: truthiness, addr1
	and
	o1 @
	or
	dbg
	rp@ !	\ write it back
	;


:x xzbranch
	0= 
	rp@ @	\ fetch return address
	dup
	@	\ fetch content at the return address, i.e. the next cell in the caller
	dbg	\ 3 values: truthiness, addr1, addr2
	2pick and
	dbg	\ first address ANDed with truthiness
	rot rot	\ move it back
	dbg	\ second addr and truthiness on top
	CELL+
	swap not
	dbg	\ negated truthiness, plus the other address
	and
	or
	dbg
	rp@ !	\ write it back
	;



\ : BRANCH RP@ @ DUP @ + 2 + RP@ ! ;
\ : ?BRANCH 0= RP@ @ @ AND RP@ @ + 2 + RP@ ! ;
:x xzbranch
	\ dbg
0 xor
\	0=		\ is the cell zero? yes => -1, no => 0
	rp@ @		\ fetch return address
	@		\ fetch content at the return address, i.e. the next cell in the caller
\	CELL_SIZE -	\ subtract a cell size
	dbg

	and		\ mask origin address with the truth value. I.e., 0 if false, otherwise lit
	\ dbg		\ This is now the same as the two words "lit" "<number>"
	rp@ @
\	+		\ fetch return address again, offset it by lit
\	CELL+		\ add CELL_SIZE??
	\ rp@ dbg !	\ write value as our return address
	rp@ !	\ write value as our return address
	;

\ relative branch, untested
:x xbranch
	rp@ @	\ fetch return address
	\ dbg
	dup @	\ fetch content at the return address, i.e. the next cell in the caller
	not CELL+ not
	\ dbg
	+	\ add that value to our current return address
	CELL+
	\ rp@ dbg !	\ write it back
	rp@ !	\ write it back
	;



:? dup0< dup 0< ;
variable p1
variable p2
\ FAST
: p+
	p1 !
	begin
		p1 @ 1+     p1 !
		\ dbg
		1- dup0<
		if
			drop
			p1 @
			1-
			EXIT
		then
	again
	;NORETURN

: p-
	p1 !
	begin
		p1 @ 1-     p1 !
		\ dbg
		1- dup0<
		if
			drop
			p1 @
			1-
			EXIT
		then
	again
	;NORETURN

\ inlineable
: q+
	p1 !
	begin
		p1 @ 1+ p1 !
		1- dup0<
	until
	drop
	p1 @ 1-
	;

: q-
	p1 !
	begin
		p1 @ 1- p1 !
		1- dup0<
	until
	drop
	p1 @ 1-
	;


\ without vars. problems in recursive functions...
: o+
	>r
	begin
		rsinc
		\ dbg
		1- dup0<
		if
			drop
			r@ rsdrop
			1-
			EXIT
		then
	again
	;NORETURN

: o-
	>r
	begin
		rsdec
		\ dbg
		1- dup0<
		if
			drop
			r@ rsdrop
			1-
			EXIT
		then
	again
	;NORETURN


: r+
	>r
	begin
		rsinc
		dbg
		1- dup
		0=
		if
			r@ rsdrop
			EXIT
		then
	again
	;NORETURN

: u+
	>r
	begin
		rsinc
		1-
		dup 0=
		if
			\ Temit
			r@ rsdrop
			EXIT
		then
	again
	;NORETURN

: u-
	>r
	begin
		rsdec
		1-
		dup 0=
		if
			\ Temit
			r@ rsdrop
			EXIT
		then
	again
	;NORETURN

:? +
	over 0< if
		swap negate swap
		q-
	else
		q+
	endif
	;

\ plus with just 2* and nand
:x +
	begin
		2dupswap and 2* >r  \ carry
		xor rp@ @ rsdrop          \ carryless add
		dup 0<>
		\ dbg
	until
	drop
	;

\ PLOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOS 
#if !PLUS
:? 2* dup + ;
#endif
: xxxxlit32 rp@ @ dup CELL+ rp@ ! @ ;
( requires negate, which requires plus. Or at least 1+ )
:x 0= dup0< swap negate 0< or ;

variable ct
: normalize
	NOINLINE
	31 ct !
	begin

		dup 2* dbg or
		dbg
		\ int3


		ct @ 1- dup ct !
		\ dbg
		if
			Temit
		else
			Femit
			leave
		then
	again
	;


:? - negate + ;

\ :? drop dup - + ;
( a b	- dup
  a b b - -
  a 0   - +
  a
)

: 2drop drop drop ;

: pos2 sp@ CELL_SIZE*2 + ;
\ : pos3 sp@ CELL_SIZE*3 + ;
\ PLOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOS 


\ :? i rp@ CELL+ @ ;
:? i r@ ;
:? j rp@ CELL_SIZE*2 + @ ;
\ : r> r@ rsdrop ;
\ : r> NOINLINE rp@ CELL+ @ rsdrop ;
\ :? r@ rp@ CELL_SIZE*1 + @ ;
\ : r@ rp@ CELL_SIZE*1 + @ ;




\ : LIT RP@ @ 2 ( 4 ) + DUP RP@ ! @ ;
\ : LIT
\ 	RP@ @		\ get return address			( -- ret )
\ 	DUP CELL+ 	\ duplicate, add CELL_SIZE to it	( -- ret ret+4 )
\ 	RP@		\ return addr				( -- ret ret+4 ret )
\ 	!		\ return is now ret+4			( -- ret )
\ 	@		\ fetch from ret			( -- LIT )
\ 	;

\ : LIT
\ 	RP@ @ DUP	\ get return address			( -- ret ret )
\ 	CELL+	 	\ add CELL_SIZE to it			( -- ret ret+4 )
\	2 PICK		\ get original retaddr again		( -- ret ret+4 ret )
\ 	!		\ return is now ret+4			( -- ret )
\ 	@		\ fetch from ret			( -- LIT )
\ 	;

\ : xlit32 rp@ @ 1 + dbg dup rp@ ! @ ;
\ : xlit32 rp@ @ dup CELL_SIZE + dbg rp@ dbg ! @ dbg ;
\ : xlit32 rp@ @ dup CELL+ dbg rp@ dbg ! @ dbg ;
\ : xlit32 rp@ @ dup CELL+ rp@ ! @ ;
\ xlit32 version for use with rpsp@
\ the other version does not work... because something something we're messing with the return stack/program flow
\ or because we can't just add +4 to rp to get the right value?
\ -> NO, CELL+ got interpreted as constant by parse.pl, thus the whole thing was broken
\ : xlit32 int3 rp@ int3 @ dup CELL+ rpsp@ drop ! @ ;
\ : xlit32 rpsp@ drop @ dup CELL+ rpsp@ drop ! @ ;
\ : xlit32 rpsp@ drop rp@ dbg @ dup CELL+ rpsp@ drop ! @ ;
\ :   xlit32 rpsp@ drop @ dup CELL+ rp@ ! @ ;
\ : xlit32 lit32 ;
\ :? 0< 0x80000000 and ;
\ :? 0< 0x7fffffff not and ;
:? < - 0< ;

: x0<> x0= not ;
\ :? absbranch rp@ ! ;
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


\ :? 0< 0x80000000 and ;


: rsinci ALWAYSINLINE rsinc i ;
: i1+ ALWAYSINLINE rsinci ;

:? xx0+
	>r
	begin
		1-
		rsinc

		dup 0=
		if
			false
		else
			true
		then
	until
	\ 50 demit
	r@ rsdrop
	\ 33 demit

	;


: divmin negate q+ ;

:? divmod
	( num div )
	swap
	( div num )

	0 rspush

	begin
		over
		( div num div )
		\ dbg
		-
		dup0<
		if
			\ dbg
			+
			\ dbg
			r@ rsdrop
			\ dbg
			EXIT
		then
		rsinc
	again
	;NORETURN

: 10+ 8+ 2+ ;

\ slow variant just using divmod
:x 10divmod 10 divmod ;

\ using begin..until to allow inlining
: 10divmod
	0 >r
	begin
		not 10+ not
		rsinc
		dup0<
	until
	10+
	r@ rsdrop 1-
	;

\ using return stack
:x 10divmod
	0 >r
	begin
		not 10+ not
		dup0<
		if
			\ strange things happening here if I use '+'. Nested addition?
			10+
			r@ rsdrop
			EXIT
		then
		rsinc
	again
	;NORETURN

: 2divmod
	0 >r
	begin
		not 2+ not
		rsinc
		dup0<
	until
	2+
	r@ rsdrop 1-
	;



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
			r@ rsdrop
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

: syscall3_noret syscall3 drop ;

#if !CHAIN
: emit
	1
	emitn
	;

: emitn
	sp@
	CELL+
	STDOUT
	SYS_write
	syscall3_noret
	drop
	;
#endif

: u.
	10divmod

	dup
	if
		u.
	else
		drop
	then

	'0' +
#if CHAIN
	;CONTINUE
: emit
	1
	;CONTINUE

: emitn
	sp@
	CELL+
	STDOUT
	SYS_write
	syscall3_noret
	drop
	;

#else
	emit ;
#endif

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


\ : bye SYS_exit syscall3_noret ; 
: SYS_exit 1 ;
: bye SYS_exit syscall3 ; 
: xbye 1 syscall7 ;
: xsleep 0 swap sp@ 0 swap 162 syscall3_noret drop ;
: sleep 0 over 0 pos1 162 syscall3_noret 2drop ;


\ : 0<> if true  else false then ;
\ :? 0<> 0= not ;
\ : =  - 0=  ;
\ : <> = not ;
\ : <>2 - 0<> ;
\ : <> - 0<> ;
\ : <> - ;
\ : = <> not ;
: up ALWAYSINLINE r@ = ;
\ so woah... if equal, then x + (not x) will be 0xFF.... == -1 == true
\ because... (not x) is the inverse of x... and if no overlap, then "+" is equal to "or"
\ : = not + ;
\ : <> invert + invert ;

\ ######################
\ END OF LIBRARY
\ ######################

