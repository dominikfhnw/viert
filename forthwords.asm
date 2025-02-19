DEFFORTH "exit"
	lit	1
	f_syscall3
ENDDEF noreturn

DEFFORTH "puts"
	f_swap
	lit	1 ;stdout
	lit	4 ;write
	f_syscall3
	f_drop
ENDDEF

DEFFORTH "heya"
	string "heya"
	f_puts
ENDDEF

DEFFORTH "triple"
	f_heya
	f_heya
	f_heya
ENDDEF


