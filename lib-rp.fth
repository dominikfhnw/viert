\ This file gets preprocessed by cpp 
: ANYLIT sp@ ;

:? dup sp@ @ ;
#include "lib/tos-basic1.fth"

: false ANYLIT dropfalse ;
: true false not ;

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

: 1- not 1+ not ;
: 2- not 2+ not ;
: 4- not 4+ not ;
: CELL+ 4+ ;
: CELL- 4- ;
: getpid ANYLIT ANYLIT ANYLIT false 4+ 4+ 4+ 4+ 4+ syscall3 ;
: negate not 1+ ;

: rp0 ( -- rp ) ALWAYSINLINE dup rp3 drop drop ;
: xr@ ALWAYSINLINE rp@ @ ;
: xr> ALWAYSINLINE xr@ rsdrop ;
: xlit32 NOINLINE rp0 @ dup CELL+ rp0 ! @ ;

: varhelper NOINLINE rp0 @ rsdrop ;
variable o1
variable o2
:? swap
	\ w/o variables
	\ 2dup
	\ pos3 !
	\ pos1 !
	
	\ w/ variables
	o1 ! o2 !
	o1 @ o2 @
	;
:? rp@ ( -- rp ) NOINLINE rp3 drop swap CELL+ ;

#include "lib/rest.fth"
