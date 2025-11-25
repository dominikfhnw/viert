#!/bin/bash

sed 's/ sp@ @/ dup/g' f2 |\
	sed 's/ sp@ @/ dup/g' |\
	sed 's/dup nand /not /g' |\
	sed 's/dup not nand /droptrue /g' |\
	sed 's/dup droptrue /true /g' |\
	sed 's/true not /0 /g' |\
	sed 's/nand not /and /g' |\
	sed 's/droptrue and /drop /g' |\
	sed 's/0x80000000 and /0< /g' |\
	sed 's/1+ 1+ /2+ /g' |\
	sed 's/2+ 2+ /4+ /g' |\
	sed 's/4+ 4+ /8+ /g' |\
	sed 's/8+ 8+ /16+ /g' |\
	sed 's/16+ 16+ /32+ /g' |\
	sed 's/32+ 32+ /64+ /g' |\
	sed 's/sp@ 4+ @ /over /g' |\
	sed 's/o1 ! o2 ! o1 @ o2 @ /swap /g' |\
	sed 's/not 1 + /negate /g' |\
	sed 's/true dup + not /1 /g' |\
	sed 's/1 + /1+ /g' |\
	sed 's/not 1+ /negate /g' |\
	sed 's/negate not /1- /g' |\
	sed 's/sp@ CELL+ CELL+ @ /2pick /g' |\
	sed 's/dbg //g' |\
	sed 's/dup 0< not swap negate 0< not and /0= /g' |\
	sed 's/not nand /imply /g' |\
	sed 's/0 1+ /1 /g' |\
	sed 's/0 4+ /4 /g' |\
	sed 's/sp@ 1 over 1 4 syscall3 drop drop drop /demit /g' |\
less
#	sed 's/ not 1 +/ negate/g' |\
#	sed 's/ negate +/ -/g' |\
#	sed 's/ dup - +/ drop/g' |\
#	sed 's/ sp@ 4 + 1 4 syscall3 drop drop/ emitn/g' |\
#	sed 's/ nand not/ and/g' |\
#	sed 's/ 0 not/ true/g' |\
#	sed 's/ sp@ 4 +/ pos1/g' |\
#	sed 's/ pos1 @/ over/g' |\
#	sed 's/ sp@ 12 +/ pos3/g' |\
#	sed 's/ 1 syscall3/ bye/g' |\
#	sed 's/ if 0 else true then/ 0=/g' |\
#	sed 's/ divmod drop/ div/g' |\
#	sed 's/ i rsdrop/ r>/g' |\
#	sed 's/ rspush/ >r/g' |\
#	sed 's/ over over pos3 ! pos1 !/ swap/g' |\
#	sed 's/ >r swap r> swap/ rot/g' |\

:<<'COMMENT'
	sed 's/dup nand /not /g' |\
	sed 's/dup not nand /droptrue /g' |\
	sed 's/dup droptrue /true /g' |\
	sed 's/true not/0/g' |\
	sed 's/droptrue a/DROPtrue A/g' |\
	sed 's/1+ 1+ /2+ /g' |\
	sed 's/2+ 2+ /4+ /g' |\
	sed 's/4+ 4+ /8+ /g' |\
	sed 's/8+ 8+ /16+ /g' |\
	sed 's/16+ 16+ /32+ /g' |\
	sed 's/ 0/ false/g' |\
COMMENT
