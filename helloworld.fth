( 
	# I'm also a bash script
	FULL=${FULL-} SOURCE=$0 bash viert3.asm -DWORD_ALIGN=1
	kill $$ # the forth comment counts as a subshell, so this is the easiest way to exit
)

: puts
	swap
	STDOUT
	SYS_write
	syscall3
	\ drop \ we don't care about cleaning up
	SYS_exit
	syscall3
	;

MAIN
\ dotstr internally calls puts
dotstr `hello\40world\n`
