DEFFORTH "false"
	lit 0
ENDDEF

DEFFORTH "true"
; defining true as -1 allows use to just use binary "not" to invert booleans
; this is much more elegant than to use 0 and 1, and then having a special
; "0=" word like in jonesforth.
; -1 feels more like the Forth way.
; This also just uses the first Peano axiom. I don't know any number except
; 0, and frankly I do not want to know any other numbers.
	f_false
	f_not
ENDDEF

%ifndef f_dec
DEFFORTH "dec"
; curiously, we can define dec before inc, even though we only have "plus"
; and "not" as primitives.
	f_true
	f_plus
ENDDEF
%endif

%define f_0 f_false

DEFFORTH "1"
; Ok, let's also use the successor of zero. It makes things easier.
	lit 1
ENDDEF

%ifndef f_inc
DEFFORTH "inc"
; So this jumps wildly ahead of what started with the first Peano axiom.
; But truth is, performance is much better with defining increment in terms
; of plus than the other way around.
	f_1
	f_plus
ENDDEF
%endif

%ifndef f_negate
DEFFORTH "negate"
	f_not
	f_inc
ENDDEF
%endif

%ifndef f_minus
DEFFORTH "minus"
	f_negate
	f_plus
ENDDEF
%endif

DEFFORTH "exit"
	f_1
	f_syscall3
ENDDEF noreturn

DEFFORTH "2dup"
	f_over
	f_over
ENDDEF

DEFFORTH "2drop"
	f_drop
	f_drop
ENDDEF


DEFFORTH "div"
	f_divmod
	f_drop
ENDDEF

DEFFORTH "mod"
	f_divmod
	f_swap
	f_drop
ENDDEF

%if 0
DEFFORTH "bool"
	if
		f_true
	else
		f_false
	then
ENDDEF
%endif


DEFFORTH "puts"
	f_swap
	lit	1 ;stdout
	lit	4 ;write
	f_syscall3
	f_drop
ENDDEF

%if 0
DEFFORTH "xputs"
	f_swap
	lit	0 ;stdin; yep, that works, as long as stdin is a tty
	lit	4 ;write
	f_syscall3
	f_drop
ENDDEF
%endif

DEFFORTH "emit"
	f_sp_at
	lit 1
	f_puts
	f_drop
ENDDEF

%if 0
DEFFORTH "loopdec"
	;f_upget
	f_rspop
	f_dec
	f_dup
	f_rspush
	;f_zbranch
ENDDEF

DEFFORTH "frdrop"
	f_rspop
	f_drop
ENDDEF

DEFFORTH "tos"
	f_sp_at
	lit 4
	f_puts
ENDDEF
%endif

DEFFORTH "nl"
	lit `\n`
	f_emit
ENDDEF

%if 0
DEFFORTH "brk"
	f_0
	f_dup
	f_rot
	lit 45
	f_syscall3
ENDDEF

DEFFORTH "mem"
	f_0
	f_brk
	lit 0x10000
	f_plus
	f_brk
ENDDEF

DEFFORTH "char"
	lit 'E'
	f_emit
ENDDEF

DEFFORTH "nop"
ENDDEF
%endif

;DEFFORTH "emitdigit"
;	; convert to ascii
;	lit '0'
;	f_plus
;	f_emit
;ENDDEF

DEFFORTH "udot"

	doloop 10
		lit 10
		f_divmod
	endloop

	f_drop

	doloop 10
		lit '0'
		f_plus
		f_emit
	endloop

	f_nl

ENDDEF

DEFFORTH "dot"
	f_dup
	lit 0x80000000
	f_and
	if
		string "-"
		f_puts
		f_negate
	then
	f_udot
ENDDEF

%if 0
DEFFORTH "dbg"
	f_dup
	f_dot
	f_rot
	f_rot

	f_dup
	f_dot
	f_rot
	f_rot

	f_dup
	f_dot
	f_rot
	f_rot

ENDDEF


DEFFORTH "fib"
	f_2dup
	f_plus
	f_dup
	f_dot
	f_fib
ENDDEF
%endif
