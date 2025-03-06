%ifndef f_dup
DEFFORTH "dup"
	f_sp_at
	f_fetch
	END
	%endif

%ifndef f_not
DEFFORTH "not"
	f_dup
	f_nand
	END
	%endif

%ifndef f_over
DEFFORTH "over"
	f_sp_at
	lit 8
	f_plus
	f_store
	END
	%endif

%ifndef f_and
DEFFORTH "and"
	f_nand
	f_not
	END
	%endif

%if 0
DEFFORTH "true"
	; lit saves us a lot of space overall, but this was an interesting
	; exercise nonetheless
	f_dup
	f_dup
	f_not
	f_nand
	END
	%endif


%ifndef f_swap
DEFFORTH "swap"
	;: swap ( x y -- y x ) over over sp@ 6 + ! sp@ 2 + ! ;
	; TODO: can probably be made smaller
	f_over
	f_over
	f_sp_at
	lit 12
	f_plus
	f_store
	f_sp_at
	lit 4
	f_plus
	f_store
	END
	%endif

%ifndef f_rspush
DEFFORTH "rspush"
	f_not
	f_and
	END
	%endif

DEFFORTH "false"
	lit 0
ENDDEF

DEFFORTH "true"
; defining true as -1 allows use to just use binary "not" to invert booleans.
; This is much more elegant than to use 0 and 1, and then having to use
; "0=" for negation like in jonesforth.
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

%ifndef f_branch2
DEFFORTH "branch2"
	f_rp_at
	f_fetch
	f_plus
	f_rp_at
	;lit 4
	;f_minus
	f_store
	END
	%endif

%ifndef f_drop
DEFFORTH "drop"
	f_dup
	f_minus
	f_plus
	END
	%endif


%ifdef	f_syscall3
DEFFORTH "exit"
	f_1
	f_syscall3
	END noreturn
	%endif

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


%if 0
DEFFORTH "puts"
	f_swap
	lit	1 ;stdout
	lit	4 ;write
	f_syscall3
	f_drop
ENDDEF
%endif

DEFFORTH "emit"
	%if 0
		f_sp_at
		lit 1
		f_puts
		f_drop
	%else
		f_dupemit
		f_drop
	%endif
ENDDEF

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

%endif

%if 0
DEFFORTH "qdup"
	f_dup
	if
		f_dup
	then
	END
	%endif

DEFFORTH "udot"
	lit 10
	f_divmod

	%ifdef f_qdup
		f_qdup
		if
			f_udot
		then
	%else
		f_dup
		if
			f_udot
		else
			f_drop
		then
	%endif


	;f_drop

	lit '0'
	f_plus
	f_emit


ENDDEF

DEFFORTH "dot"
	f_dup
	lit 0x80000000
	f_and
	if
		lit '-'
		f_emit
		f_negate
	then
	f_udot
ENDDEF
