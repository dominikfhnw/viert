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
	ychg	eax, ebp
%else
	enter	0xFFFF, 0
	; data stack should be the unlimited segment normally. +2 bytes
	;xchg	esp, ebp
%endif

;rwx

%if !WORD_TABLE && WORD_SIZE == 4
	mov	FORTH_OFFSET, FORTH
	%if WORD_FOOBEL
		jmp	[FORTH_OFFSET]
	%else
		jmp	A_NEXT
	%endif
%elif 0 && !WORD_TABLE && WORD_SIZE == 1
	%error borked
	rset	TABLE_OFFSET, 0
	set	TABLE_OFFSET, ORG
	%define OFF (FORTH - $$ - 2 + ELF_HEADER_SIZE)
	;set	eax, FORTH - 2
	mov	eax, TABLE_OFFSET
	mov	al, OFF
	;DOCOL
%else

	; this is slightly confusing, as we're misusing the TABLE_OFFSET
	; variable for ASM_OFFSET
	rset	TABLE_OFFSET, 0

	%if WORD_TABLE ==  1 && WORD_SMALLTABLE == 0
		mov	TABLE_OFFSET, STATIC_TABLE
	%else
		set	TABLE_OFFSET, ORG
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
	;mprotect edi, 0xFFFF,7
	;mov	ebx, esp
	;xor	bx, bx
	;mprotect ebx, 0x2000,6
	;mprotect 0x10000, 0x1000,6

	;mov	[edi], dword A_NEXT
	%define OFF (FORTH - $$ - 2 + ELF_HEADER_SIZE)

	; XXX magic
	%if 0 ; some magic that doesn't always works
		mov	eax, TABLE_OFFSET
		mov	al, OFF
		;lea	eax, [TABLE_OFFSET + OFF]
	%else ; simple but slightly larger
		%if THRESH
			mov	esi, FORTH
		%else
			mov	eax, FORTH - 2
		%endif
	%endif

	;lea	eax, [TABLE_OFFSET  + OFF]
	;DOCOL
%endif



