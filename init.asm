enter	0xFFFF, 0
%if OFFALIGN
	%if BASEREG
		set	BASE, ORG
	%endif
%else
	%if BASEREG
		mov	BASE, ASM_OFFSET
	%endif
%endif

