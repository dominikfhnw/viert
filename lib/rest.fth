#if BITS == 64
: SYS_exit	 60 ;
: SYS_write	  1 ;
#else
: SYS_exit	  1 ;
: SYS_read	  3 ;
: SYS_write	  4 ;
: SYS_poll	168 ;
#endif
: STDIN		  0 ;
: STDOUT	  1 ;

:? dup0< dup 0< ;
: 0<> dup0< not swap negate 0< not nand ;
: 0= 0<> not ;
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

: type STDOUT SYS_write syscall3_noret ;
: writestdout type ;

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

: bye SYS_exit syscall3_noret ; 
: xbye SYS_exit syscall7 ;
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












: = - 0= ;
: <> = not ;

: 2drop drop drop ;

:? j rp@ CELL_SIZE*2 + @ ;


: rsinci ALWAYSINLINE rsinc i ;
: i1+ ALWAYSINLINE rsinci ;


: rot >r swap r@ rsdrop swap ;
: -rot rot rot ;


\ ************  BRANCHING NEEDED FROM HERE
#if 0
variable t
: >t t ! ;
: t@ t @ ;
: t1+ t@ 1+ >t ; \ t@ instead of t> allowed here, because in this case we now t is just a single variable and not a stack
: t1- t@ 1- >t ;
:  t1+@ t1+ t@ ;
:x t1+@ t@ 1+ dup >t ;

: t> t@ 0 >t ;
\ t0 0 >t ; \ reset t
: t0 ; \ if we're sure t gets properly cleared at the end of every word that uses it
#else
: >t ALWAYSINLINE >r ;
: t@ ALWAYSINLINE i ;
: t1+ ALWAYSINLINE rsinc ;
: t1- ALWAYSINLINE rsdec ;
: t> ALWAYSINLINE i rsdrop ;
: t0 ALWAYSINLINE 0 >r ;
#endif

variable p1
\ inlineable
#if 1
: q+
	>t
	begin
		t1+
		1- dup0<
	until
	drop
	t> 1-
	;

: q-
	>t
	begin
		t1+
		1- dup0<
	until
	drop
	t> 1-
	;
#else
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
#endif
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
:? >= < not ;
:? > 1+ >= ;

\ ************  PLUS+BRANCHING NEEDED FROM HERE
#if 1
variable divi	\ XXX needed if >t/t> uses return stack
		\ due to rsinc/rp@ using swap
:? divmod
	( num div )
	o2 ! ( num )
	t0
	begin
		t1+
		o2 @ ( num div )
		- ( num-div )
		dup0<
	until
	o2 @ +
	\ dbg
	t> 1-
	;
#else
:? divmod
	( num div )
	swap
	( div num )

	t0

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
			t>
			\ dbg
			EXIT
		then
		t1+
	again
	;NORETURN
#endif

:x divmod
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
\ using var instead of return stack
: 10divmod
	t0
	begin
		not 10+ not
		t1+
		dup0<
	until
	10+
	t> 1-
	;

\ using begin..until to allow inlining
:x 10divmod
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
		45 emit \ "-"
		negate
	then
	u. space
	;


\ ######################
\ END OF LIBRARY

\ ######################

