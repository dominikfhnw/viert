enter	0xFFFF, 0
%if !WORD_TABLE && WORD_SIZE == 4
%else
	%if WORD_TABLE ==  1 && WORD_SMALLTABLE == 0
		mov	edi, STATIC_TABLE
	%else
		%if OFFALIGN
			%if BASEREG
				set	BASE, ORG
			%endif
		%else
			%if BASEREG
				mov	BASE, ASM_OFFSET
			%endif
		%endif
	%endif
%endif

