\ / 2>&-;	rm -rf ./6 && LIT8=1 ASM="i swap dup syscall3" FULL=${FULL-} TOS_ENABLE=0 ./optim.sh $0 && setarch -R strace -b execve -rni ./viert; exit
\ / 2>&-;	rm -rf ./6 && FULL=${FULL-} TOS_ENABLE=0 SMALLASM=0 ./optim.sh $0 && setarch -R strace -b execve -rni ./viert; exit
 

: creat		  8 syscall3 ;
: open		  5 syscall3 ;
: sendfile	187 syscall3 ;
: execve	 11 syscall3 ;
: getppid	 64 syscall3 ;
: kill		 37 syscall3 ;

: print6
	1 string0 "6"
	type
	;

: creat6
	0
	54	\ ascii '6'
	sp@
	creat
	;

: killbash
	getppid
	6	\ a.k.a SIGABRT
	swap
	kill
	;

: download6
	0	\ null to end array
	string0 "6l.al"
	string0 "-L"
	dup	\ exec name can be anything
	sp@	\ array of pointers
	0	\ env
	swap

	string0 "/bin/curl"
	execve
	\ int3
	;NORETURN


rsdrop i \ drop random junk, argc; get argv[0]
open

\ print6 
creat6
\ dbg
sendfile
\ dbg

killbash

download6
\ print6
\ bye
