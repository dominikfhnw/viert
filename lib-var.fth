\ This file gets preprocessed by cpp 
: ANYLIT rp@ ;

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


: CELL+ 4+ ;
: getpid ANYLIT ANYLIT ANYLIT false 4+ 4+ 4+ 4+ 4+ syscall3 ;
: negate not 1+ ;

: xr@ ALWAYSINLINE rp@ @ ;
: xr> ALWAYSINLINE xr@ rsdrop ;
: xlit32 NOINLINE xr@ xr@ CELL+ rp@ ! @ ;

: varhelper NOINLINE xr> ;
variable o1
variable o2
: dup o1 ! o1 @ o1 @ ;
#include "lib/tos-basic1.fth"

:? swap
	\ w/o variables
	\ 2dup
	\ pos3 !
	\ pos1 !
	
	\ w/ variables
	o1 ! o2 !
	o1 @ o2 @
	;
:? sp@ sp3 drop swap not CELL+ not ;

#include "lib/rest.fth"
