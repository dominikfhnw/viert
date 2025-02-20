DEFFORTH "exit"
	lit	1
	f_syscall3
ENDDEF noreturn

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

%if 1

DEFFORTH "mem"
	lit 0
	f_dup
	f_dup
	f_dup
	f_dup
	lit 45
	f_syscall3
	lit 0x10000
	f_plus
	lit 45
	;f_swap
	f_syscall3
ENDDEF
%endif

DEFFORTH "char"
	lit 'E'
	f_emit
ENDDEF

DEFFORTH "dotstep"
	; divide TOS by 10
	lit 10
	f_divmod

	; convert to ascii
	lit '0'
	f_plus

	; print
	f_emit

ENDDEF

DEFFORTH "dot"
	;string `parsing...\n`
	;f_puts
	%if 0
		lit 8
		.loop:
		f_dotstep
		f_dec
		f_zbranch
		db .loop - $ - 1
	%else
		f_dotstep
		f_dotstep
		f_dotstep
		f_dotstep
		f_dotstep
		f_dotstep
		f_dotstep
		f_dotstep
		f_dotstep
	%endif

	f_nl

ENDDEF
