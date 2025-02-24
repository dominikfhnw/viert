DEFFORTH "lit0"
	lit 0
ENDDEF

DEFFORTH "exit"
	lit 1
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


%if 0
DEFFORTH "dec"
	lit 1
	f_negate
	f_plus
ENDDEF
%endif

DEFFORTH "div"
	f_divmod
	f_drop
ENDDEF

DEFFORTH "mod"
	f_divmod
	f_swap
	f_drop
ENDDEF

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

DEFFORTH "nl"
	lit `\n`
	f_emit
ENDDEF

DEFFORTH "brk"
	f_lit0
	f_dup
	f_rot
	lit 45
	f_syscall3
ENDDEF

DEFFORTH "mem"
	f_lit0
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

DEFFORTH "dotstep"
	; divide TOS by 10
	lit 10
	f_divmod
ENDDEF

DEFFORTH "emitdigit"
	; convert to ascii
	lit '0'
	f_plus
	f_emit
ENDDEF

DEFFORTH "dot"

	doloop 10
		f_dotstep
	endloop

	doloop 10
		f_emitdigit
	endloop

	f_nl

ENDDEF

DEFFORTH "fib"
	f_2dup
	f_plus
	f_dup
	f_dot
	f_fib
ENDDEF
