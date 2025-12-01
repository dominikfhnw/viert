:? dup0< dup 0< ;
: 0= dup0< not swap negate 0< not and ;
\ absolute branch
: xbranch
	NOINLINE
	xr@	\ fetch return address
	@	\ fetch content at the return address, i.e. the next cell in the caller
	rp@ !	\ write it back
	;

\ From Hackers Delight, "Manipulating Rightmost Bits", algorithm 7
\ converts a non-0 integer to... something with quite a bit of 1 bits
\ For further info:
\ H. S. Warren, ‘Functions realizable with word-parallel logical and two’s-complement addition instructions’, Commun. ACM, vol. 20, no. 6, pp. 439–441, Jun. 1977, doi: 10.1145/359605.359632.
\ in short, checking if a value is 0 is not right-to-left computable, so we *need* an additional function like 0< or right-shift. 
\ This functions seems to be the best we can do in the confines of just having 1+ and nand, but it is not sufficient for universal computability
: hdr          dup 1- swap imply ;
\ hdr NOINLINE dup 1- swap imply ;

\ absolute zbranch v0
\ Recognized inputs:
\ all 0s:	False
\ all 1s:	True
\ other inputs:	undefined behaviour. 
\ NOT compliant with Forth2012
: zbranch0
	ALWAYSINLINE
	dup not \ our copy of negated truthiness
	xr@	\ fetch return address
	\ dup
	CELL+	\ we want to skip over the address if false
	nand \ negated truthiness plus our skip address, negated
	\ dbg
	swap

	xr@ @	\ fetch content at the return address, i.e. the next cell in the caller
	\ dbg	\ 2 values: truthiness, addr1
	nand	\ truthniness plus jump address, negated

	nand	\ final branch value
	\ dbg
	rp@ !	\ write it back
	;

\ absolute zbranch v1
\ Recognized inputs:
\ all 0s:	False
\ LSB is 1:	True
\ other inputs:	undefined behaviour. 
\ NOT compliant with Forth2012
: zbranch1 ALWAYSINLINE hdr zbranch0 ;

\ absolute zbranch v2
\ Recognized inputs:
\ all 0s:	False
\ other inputs:	True
\ COMPLIANT with Forth2012
: zbranch2 ALWAYSINLINE 0= zbranch0 ;

: xzbranch NOINLINE zbranch2 ;

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
: 16+ 8+ 8+ ;
: 32+ 16+ 16+ ;
: inc 1+ ;
: dec 1- ;

: pos1 sp@ CELL+ ;
: pos2 sp@ CELL*2+ ;
: pos3 sp@ CELL*2+ CELL+ ;
:? over pos1 @ ;
: 2pick pos2 @ ;
: 3pick pos3 @ ;


\ xlit32 xr@ dup CELL+ rp@ ! @ ;
\  rp orig sp
\ rp0 ( -- rp true rp ) true rp3 drop over ;
\ rp0 ( -- rp true rp ) dup rp3			( rp anything sp )
\	drop drop				( rp )
\ drop over ;
\ : LIT
\ 	RP0 @		\ get return address			( -- rp true ret )
\ 	DUP CELL+ 	\ duplicate, add CELL_SIZE to it	( -- rp true ret ret+4 )
\ 	RP@		\ return addr				( -- rp true ret ret+4 rp true rp )
\ 	!		\ return is now ret+4			( -- ret )
\ 	@		\ fetch from ret			( -- LIT )
\ 	;

\ : LIT RP@ @ 2 ( 4 ) + DUP RP@ ! @ ;
\ : LIT
\ 	RP@ @		\ get return address			( -- ret )
\ 	DUP CELL+ 	\ duplicate, add CELL_SIZE to it	( -- ret ret+4 )
\ 	RP@		\ return addr				( -- ret ret+4 rp )
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
: xlit8  xr@ dup 1+    rp@ ! @ 255 and ;


\ ************  LITERALS NEEDED FROM HERE
#include "demit.fth"

:x syscall3
	0 3pick 3pick 3pick
	syscall7
;

:x syscall3_noret syscall3 drop ;

: key
	0	\ key gets saved here
	1
	sp@ CELL+
	STDIN
	SYS_read
	syscall3_noret
	;

: writestdout STDOUT SYS_write syscall3_noret ;

#if !CHAIN
: emitn
	sp@
	CELL+
	STDOUT
	SYS_write
	syscall3_noret
	drop
	;
: emit
	1
	emitn
	;

#endif


: nl 10 emit ;
: cr nl ;
: bl 32 ;
: space bl emit ;

\ : bye SYS_exit syscall3_noret ; 
: SYS_exit 1 ;
: bye SYS_exit syscall3_noret ; 
: xbye 1 syscall7 ;
: xsleep 0 swap sp@ 0 swap 162 syscall3_noret drop ;
: sleep 0 over 0 pos1 162 syscall3_noret 2drop ;
: up ALWAYSINLINE r@ = ;


#if RWMEM && !FULL
	: rwx 7 65536 dup 125 syscall3 drop ;
	rwx
#else
	: rwx ;
#endif


: 2dup over over ;
: nip ( a b -- b ) swap drop ;

: rflip ( r:ret1 r:ret2 val retaddr1 ret1 -- r:val r:ret1 ) 
	rp@ !
	( r:ret1 r:ret1 val retaddr1 )
	\ store new value on retstack
	!
	( r:val r:ret1 )
	;

:? >r ( r:ret1 val -- r:val ) \ also known as ">r"
	rp@ dup @
	\ rpsp@ @ @

	\ next two words can be here or in rflip. TODO rewrite
	rflip
	;
: rspush >r ;

: 2dupswap dup 2pick ;

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


:? i rp@ CELL+ @ ;
:? r@ ALWAYSINLINE i ;

\ This version is weak
:x 0< 0x80000000 and ;

: or ( x y -- x|y ) not swap imply ;
 
\ : = ( w w -- t ) xor if false EXIT then true ;	\ from eForth












: 0<> 0= not ;
: = - 0= ;
: <> = not ;

: 2drop drop drop ;

:? j rp@ CELL_SIZE*2 + @ ;


: rsinci ALWAYSINLINE rsinc i ;
: i1+ ALWAYSINLINE rsinci ;


: rot >r swap r@ rsdrop swap ;
: -rot rot rot ;


\ ************  BRANCHING NEEDED FROM HERE

variable p1
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
		xor xr@ rsdrop          \ carryless add
		dup 0<>
		\ dbg
	until
	drop
	;

#if !PLUS
:? 2* dup + ;
#endif

:? - negate + ;
:? < - 0< ;

\ ************  PLUS+BRANCHING NEEDED FROM HERE
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

: mod divmod drop ;
: div divmod nip ;
: 10+ 8+ 2+ ;

#if PLUS || NOFAST
\ slow variant just using divmod
: 10divmod 10 divmod ;
#else

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
#endif

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

#if PLUS
: 48+ 48 + ;
#else
: 48+ 32+ 16+ ;
#endif
: digit 48+ ;

: u.
	10divmod

	dup
	if
		u.
	else
		drop
	then

	digit
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
: emit4 4 emitn ;

: .
	dup0<
	if
		'-'
		emit
		negate
	then
	u. space
	;


\ ######################
\ END OF LIBRARY

\ ######################

