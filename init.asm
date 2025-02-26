; **** Assembler code ****
A_INIT:
;A_RETURNSTACK_INIT:
rinit
%if 0
	;mmap	0x10000, 0xffff, PROT_WRITE, MAP_PRIVATE | MAP_FIXED | MAP_ANONYMOUS, 0, 0
	mmap	0xffff, 0xffff, PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, 0, 0
	;mmap	0x10000, 0xffff, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_FIXED | MAP_ANONYMOUS, 0, 0
	;mmap	0x10000, 0xffff, PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, 0, 0
	add	eax, eax
	taint	eax
	ychg	eax, RETURN_STACK
%else
	enter	0xFFFF, 0
	taint	ebp
	%ifnidn RETURN_STACK,ebp
		ychg	ebp, RETURN_STACK
	%endif
	; data stack should be the unlimited segment normally. +2 bytes
	;xchg	esp, RETURN_STACK
%endif

;rwx

%if !WORD_TABLE && WORD_SIZE == 4
	mov	FORTH_OFFSET, FORTH
	%if WORD_FOOBEL
		jmp	[FORTH_OFFSET]
	%else
		jmp	A_NEXT
	%endif
%else
	%if WORD_TABLE ==  1 && WORD_SMALLTABLE == 0
		mov	BASE, STATIC_TABLE
	%else
		set	BASE, ORG
	%endif

	.brk1:
	;rtaint
	%if 1
	%elif 1
		brk	0
		set	ebx, 0xff00
		;add	eax, 4096
		;xchg	eax, ebx
		add	ebx, eax
		taint	ebx
		;rtaint
		brk	ebx
	%else
		;;set	ebx, 0
		mmap	0, 0xff00, PROT_WRITE | PROT_EXEC | PROT_READ, MAP_PRIVATE | MAP_ANONYMOUS, x, x
	%endif
	.endbrk:
	;pause
	;mprotect BASE, 0xFFFF,7
	;mov	ebx, esp
	;xor	bx, bx
	;mprotect ebx, 0x2000,6
	;mprotect 0x10000, 0x1000,6

	;mov	[BASE], dword A_NEXT
	;%define OFF (FORTH - $$ - 2 + ELF_HEADER_SIZE)

	; XXX magic
	%if 0 ; some magic that doesn't always works
		%fatal borked
		;mov	eax, BASE
		;mov	al, OFF
		;lea	eax, [BASE + OFF]
	%else ; simple but slightly larger
		%if THRESH
			mov	FORTH_OFFSET, FORTH
		%else
			mov	eax, FORTH - 2
		%endif
	%endif

	;lea	eax, [BASE + OFF]
	;DOCOL
%endif



