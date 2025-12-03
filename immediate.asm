; IMMEDIATE WORDS
; TODO: handle better

%macro string 1
	f_string
	db %%endstring - $ - 1
	db %1
	%%endstring:
%endmacro

%macro stringr 1
	f_stringr
	db %%endstring - $ - 1
	db %1
	%%endstring:
%endmacro

%macro string0 1
	f_string0
	db %%endstring - $ - 1
	db %1, 0
	%%endstring:
%endmacro

%macro print 1
	stringr %1
	lit 1
	lit 4
	f_syscall3_noret
%endmacro

%macro dotstr 1
	f_dotstr
	db %%endstring - $ - 1
	db %1
	%%endstring:
%endmacro

;%macro inline_asm 0
;	%push asmctx
;	f_string
;	db %$endasm - $ - 1
;	%$asm:
;%endmacro
;
;%macro endasm 0
;	NEXT
;	%$endasm:
;	f_asmjmp
;	%pop asmctx
;%endmacro
;
;%macro until arg(0)
;	f_zbranch
;	dbr %$dountil
;	%pop dountilctx
;%endmacro

%macro zbranch arg(1)
	%if FORTHBRANCH
		f "xzbranch"
		dbr %1
	%elifdef C_zbranchc
		f "zbranchc"
		dbr %1
		f "drop"
	%else
		f "zbranch"
		dbr %1
	%endif
%endmacro

%macro branch arg(1)
	%if FORTHBRANCH
		f "xbranch"
		dbr %1
	%else
		f "branch"
		dbr %1
	%endif
%endmacro


;%macro while arg(0)
;	f_not
;	zbranch %$dountil
;	%pop dountilctx
;%endmacro

%macro unless arg(0)
	if
	else
%endmacro

%macro if arg(0)
	%push ifctx
	zbranch %$jump1
%endmacro

%macro then arg(0)
	%$jump1:
	%ifctx elsectx
		;%error ELSECTX
		%pop elsectx
		%ifctx elsectx
			%error "nested else - did you try unless .. else .. then without activating nzbranch?"
		%endif
	%endif
	%pop ifctx
%endmacro
%defalias endif then

%macro else arg(0)
	%push elsectx
	branch %$jump1

	%$$jump1:
%endmacro

%macro do arg(0)
	%push doctx
	f_swap
	f_rspush
	f_rspush
	%$dolabel:
%endmacro

%macro swapdo arg(0)
	%push doctx
	f_rspush
	f_rspush
	%$dolabel:
%endmacro

%macro loop arg(0)
	%ifnctx doctx
		%fatal not doctx
	%endif
	%ifdef f_j
		%$j:	f_j
	%else
		%ifdef f_rpfetch
			f_rpfetch
		%else
			f_rpspfetch
			f_drop
		%endif
		%$lit:	lit CELL_SIZE
		%$plu:	f_plus
		%$fetc:	f_fetch
	%endif
	%$rsin:	f_rsinci
	%$minu:	f_minus
	%$if:	if
	%$bran:	jump %$$dolabel
		then
		%pop doctx
%endmacro

%macro loople arg(0)
%ifdef f_iloop
	f_iloop
	dbr %$dolabel
%else
	%ifnctx doctx
		%fatal not doctx
	%endif
	%$rsin:	f_rsinci
	%ifdef f_j
		%$j:	f_j
	%else
		%ifdef f_rpfetch
			f_rpfetch
		%else
			f_rpspfetch
			f_drop
		%endif
		%$lit:	lit CELL_SIZE
		%$plu:	f_plus
		%$fetc:	f_fetch
	%endif
	%$minu:	f_not
		f_plus
	%$if:	if
	%$bran:	jump %$$dolabel
		then
%endif
		%pop doctx
%endmacro



%macro begin 0
	%push beginloop
	%$loop:
%endmacro

%macro again 0
	branch %$loop
	%$end:
	%pop beginloop
%endmacro

%macro f_leave 0
	%ifctx beginloop
		branch %$end
	%elifctx ifctx
		branch %$$end
	%elifctx elsectx
		branch %$$$end
	%else
		%error "unknown context for leave"
	%endif
%endmacro

%macro until 0
	%$zbr: zbranch %$loop
	%pop beginloop
%endmacro

%macro notuntil 0
	%ifdef f_nzbranch
		%$nzbr: f_nzbranch
		dbr %$loop
		%pop beginloop
	%else
		%$not0: f_not
		%$until: until
	%endif

%endmacro

%macro for 0
	f_rspush
	%push forloop
	%$forloop:
%endmacro

%macro f_xi 0
	%ifdef C_rpfetch
		f_rpfetch
	%else
		f_rpspfetch
		f_drop
	%endif
	f_fetch
%endmacro

%macro next 0
%ifdef	C_inext
	f_inext
	dbr %$forloop
%else
	%$i:	f_i
	%$dec:	f_dec
	%$dup:	f_dup
	%$rpfe:	f_rpfetch
	%$stor:	f_store

	%if 1
		if
			branch %$$forloop
		then
	%else
		f_zbranch
		dbr %$else
		branch %$forloop
		%$else:
	%endif
	f_rsdrop
%endif
%pop forloop
%endmacro
