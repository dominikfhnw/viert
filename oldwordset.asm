; TODO: deprecated, remove. Only use wordset.asm
%ifndef WORDSET
%define WORDSET 99
%endif

%if WORDSET == 0 ; empty
	%define C_bye
%elif WORDSET == 99
	%include "wordset.asm"
%elif WORDSET == 1 ; helloworld
	%define C_syscall3_noret
	%define C_stringr
	;%define C_string
	%define C_lit8

%elif WORDSET == 2	; FIZZ3
	%define C_spfetch
	%define C_lit8
	;%define C_swap
	%define C_syscall3
	%define C_drop
	%define C_EXIT
	%define C_divmod
	%define C_fetch
	%define C_branch
	%define C_zbranch
	%define C_plus
	%define C_lit32
	%define C_i
	%define C_rpspfetch
	%define C_rsinci
	%define C_not
	;%define C_rspush
%elif WORDSET == 3	; FIZZ5
	%define C_spfetch
	%define C_lit8
	;%define C_swap
	%define C_syscall3
	%define C_drop
	%define C_EXIT
	%define C_divmod
	%define C_fetch
	%define C_branch
	%define C_zbranch
	%define C_plus
	%define C_lit32
	%define C_rspush
	;%define C_rpspfetch
	%if 1
		%define C_iloop
		%define C_i
		;%define C_rpspfetch
		;%define C_inext
	%else
		%define C_rpspfetch
		%define C_not
		%define C_rsinci

	%endif
%elif WORDSET == 5	; FIZZ6
	%define C_spfetch
	%define C_lit8
	%define C_syscall3_noret
	%define C_drop
	%define C_EXIT
	%define C_divmod
	%define C_fetch
	%define C_branch
	%define C_nzbranch
	%define C_plus
	%define C_lit32
	%define C_spfetch
	%define C_rsinci
	%define C_not

%elif WORDSET == 6	; FIZZ6b
	%define C_spfetch
	%define C_lit8
	%define C_syscall3
	%define C_drop
	%define C_EXIT
	%define C_divmod
	%define C_fetch
	%define C_branch
	%define C_nzbranch
	;%define C_zbranch
	%define C_plus
	%define C_lit32
	%define C_rpspfetch
	%define C_rsinci
	%define C_not

%elif WORDSET == 4	; FIZZ4

	;%define C_swap
	;%define C_divmod
	;%define C_dupemit
	;%define C_bye

	


	;%define C_bye
	;%define C_lit8
	;%define C_syscall3
	%define C_syscall3_noret
	;%define C_EXIT
	; fizz3.fth:
	%define C_branch
	%define C_zbranchc
	;%define C_zbranch
	;%define C_xzbranch
	%define C_spfetch
	;%define C_swap
	;%define C_drop
	;%define C_divmod
	%define C_EXIT
	%define C_fetch
	%define C_plus
	;%define C_rsinci
	;%define C_not
	%define C_lit32

	; less asm fizz4:
	%define C_store
	%define C_nand
	;%define C_rpfetch
	;%define C_over
	;%define C_emd

	;%define C_stringr
	;%define C_string

	;%define C_0lt
	;%define C_rot
	;%define C_dup0lt
	;%define C_divmod
	;%define C_inext
	%define MINASM 0

	;%define C_divmod


	%if !MINASM
		;%define C_rspush
		;%define C_0lt
		;%define C_swap
		;%define C_drop
		;%define C_divmod
		;%define C_over
		;%define C_rpfetch
		%define C_rpspfetch
		;%define C_inext
	%else
		%define C_rpspfetch
	%endif

%elif WORDSET == 7 ; hello3
	%define C_stringr
	%define C_syscall3

%elif WORDSET == 8 ; fib benchmark
	%define C_lit8
	%define C_syscall3
	%define C_branch
	%define C_zbranch
	%define C_spfetch
	%define C_EXIT
	%define C_fetch
	%define C_plus
	;%define C_rsinci
	%define C_not
	%define C_nand
	%define C_store
	%define C_lit32

	%if 1
	%define C_1minus
	%define C_minus
	%define C_lt
	%define C_swap
	%define C_dup
	%else
	; swap needs store
	%define C_store
	%endif

	;%define C_store
	;%define C_nand
	;%define C_over

	;%define C_rot
	;%define C_dup0lt
	;%define C_divmod
	;%define C_inext
	;%define C_iloop

	;%define C_rspush
	;%define C_dup0lt

	%define C_drop


	%define C_0lt
	%define C_divmod
	;%define C_rpfetch
%else
	%fatal illegal WORDSET
%endif

;%define C_dupemit
;%define C_dotstr
;debug
; sample.fth:
; everything undefined
