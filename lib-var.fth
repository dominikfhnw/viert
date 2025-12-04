\ This file gets preprocessed by cpp 

: false ANYLIT dropfalse ;
: true false not ;

#if PLUS
	asm "+"
	#if XLIT
		: x1 ALWAYSINLINE true true + not ;
		: x2 x1 x1 + ;
		: x4 x2 x2 + ;

		: x4+ ALWAYSINLINE x1 + x1 + x1 + x1 + ;
	#endif
#else
	: 2+ 1+ 1+ ;
	: 4+ 2+ 2+ ;
	: x4+ 4+ ;
#endif

: getpid ANYLIT ANYLIT ANYLIT false 4+ 4+ 4+ 4+ 4+ syscall3 ;

: xr@ ALWAYSINLINE rp@ @ ;
: xr> ALWAYSINLINE xr@ rsdrop ;
: xlit32 NOINLINE xr@ xr@ x4+ rp@ ! @ ;

#if PLUS
:? 1+ 1 + ;
: 4+ 4 + ;
#endif
: negate not 1+ ;
: 1- not 1+ not ;
: 4- not 4+ not ;
: CELL+ 4+ ;
: CELL- 4- ;

: varhelper NOINLINE xr> ;
variable o1
variable o2
: dup o1 ! o1 @ o1 @ ;
#if PLUS
	:? 2* dup + ;
#endif
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
:? sp@ sp3 drop swap CELL- ;

#include "lib/rest.fth"
