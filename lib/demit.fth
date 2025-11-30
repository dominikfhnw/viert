\ debug emit with minimal requirements
 
: d0	false ;
: d1	d0 1+ ;
: d4	d1 1+ 1+ 1+ ;
: femit d1 sp@ d1 d4 syscall3_noret ;

: dnl
	4
	1+ 1+ 1+ 1+ 1+ 1+
	;
: dbang
	dnl
	1+ 1+ 1+ 1+ 1+ 1+ 1+ 1+ 1+ 1+
	1+ 1+ 1+ 1+ 1+ 1+ 1+ 1+ 1+ 1+
	1+ 1+ 1+ 
	;
: dA
	dbang
	1+ 1+ 1+ 1+ 1+ 1+ 1+ 1+ 1+ 1+
	1+ 1+ 1+ 1+ 1+ 1+ 1+ 1+ 1+ 1+
	1+ 1+ 1+ 1+ 1+ 1+ 1+ 1+ 1+ 1+
	1+ 1+
	;
: dE
	dA
	1+ 1+ 1+ 1+
	;

: dH
	dE
	1+ 1+ 1+
	;

: dL
	dH
	1+ 1+ 1+ 1+
	;

: dO
	dL
	1+ 1+ 1+
	;

: demit sp@ d1 over d1 d4 syscall3_noret drop drop ;
: Temit 84 demit ;
: Femit 70 demit ;
: Bemit dbang demit ;
