\ / 2>&-;	rm -rf ./6 && TOS_ENABLE=0 SMALLASM=0 ./optim.sh $0 && setarch -R strace -b execve -rni ./viert; exit
 
asm "swap"
asm "i"
asm "dup"


: creat		  8 syscall3 ;
: open		  5 syscall3 ;
: sendfile	187 syscall3 ;
: execve	 11 syscall3 ;
: getppid	 64 syscall3 ;
: kill		 37 syscall3 ;

: print6
	stringr "6"
	writestdout
	\ rp@
	;

: creat6
	0
	54	\ ascii '6'
	sp@
	creat
	;

: killbash
	getppid
	6
	swap
	kill
	;

: download6
	0
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

creat6
\ dbg
sendfile
\ dbg

killbash

download6
\ print6
\ bye
