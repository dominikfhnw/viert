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
	lit CELL_SIZE*2
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
	lit CELL_SIZE*3
	f_plus
	f_store
	f_sp_at
	lit CELL_SIZE
	f_plus
	f_store
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

%ifndef f_bye
DEFFORTH "bye"
	%if SYSCALL64
		lit 60
	%else
		f_1
	%endif
	f_syscall3
	END
	%endif
%define f_exit f_bye

%ifdef f_syscall3
DEFFORTH "puts"
	f_swap
	lit	STDOUT
	%if SYSCALL64
		f_1
	%else
		lit	SYS_write
	%endif
	f_syscall3
	f_drop
	END
	%endif

DEFFORTH "emit"
	%ifdef f_puts
		f_sp_at
		f_1
		f_puts
		f_drop
	%else
		f_dupemit
		f_drop
	%endif
ENDDEF

DEFFORTH "0eq"
	if
		f_false
	else
		f_true
	then

	END

%if FORTHWHILE
DEFFORTH "while"
; ( rp@ -- ... )
	; make copy of address, fetch from return stack
	f_dup
	f_dup
	f_fetch

	; decrement counter
	f_dec

	f_dbg
	; swap value + address
	f_swap
	; store value back to return stack
	f_store

	; fetch again, check if zero
	f_fetch
	f_0eq
	END
%endif

%ifndef f_syscall3
DEFFORTH "puts"
	doloop1
		f_dup
		f_fetch
		f_emit
		f_inc
	endloop1
	f_drop
	f_dbg
	END
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

	lit '0'
	f_plus
	f_emit
ENDDEF

DEFFORTH "bshift"
	;f_1
	;f_swap
	doloop1
		f_dup
		f_plus
	endloop1
	END

DEFFORTH "signbit"
	%if BIT_ARITHMETIC == 64
		f_1
		lit 63
		f_bshift
	%else
		f_1
		lit 31
		f_bshift
		;lit 0x80000000
	%endif
	END

DEFFORTH "dot"
	f_dup
	f_signbit
	f_and
	if
		lit '-'
		f_emit
		f_negate
	then
	f_udot
	f_nl
ENDDEF

DEFFORTH "isnegative"
	f_dup
	f_signbit
	f_and
	END

%if 1
DEFFORTH "fib"
	f_2dup
	f_plus

	f_isnegative
	if
		f_EXIT
	then

	f_dup
	f_udot
	f_nl

	f_fib
ENDDEF
%endif
