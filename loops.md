# Different loop types
* BEGIN .. AGAIN: endless loop
* UNLOOP: remove loop control from return stack (and then e.g. EXIT the word)
* LEAVE: exit loop
* BEGIN .. WHILE .. REPEAT
* BEGIN .. UNTIL
* n FOR .. NEXT: loop counting down (https://github.com/TG9541/stm8ef/wiki/eForth-FOR-..-NEXT)
* counter: I or R@
* FOR .. AFT .. THEN .. NEXT
* FOR .. WHILE .. NEXT .. ELSE .. THEN
* limit start DO .. LOOP
* limit start ?DO .. LOOP




* BEGIN .. AGAIN: endless loop
	(MARK) .. BRANCH
* UNLOOP: remove loop control from return stack (and then e.g. EXIT the word)
	n*rdrop
* LEAVE: exit loop
	UNLOOP BRANCH
* BEGIN .. WHILE .. REPEAT
* BEGIN .. UNTIL
	(MARK) .. ZBRANCH
* n FOR .. NEXT: loop counting down (https://github.com/TG9541/stm8ef/wiki/eForth-FOR-..-NEXT)
	rspush (MARK) .. rspop 1- dup rspush ZBRANCH
* counter: I or R@
* FOR .. AFT .. THEN .. NEXT
* FOR .. WHILE .. NEXT .. ELSE .. THEN
* limit start DO .. LOOP
	rspush rspush (MARK) ..
	rspop 1+ rspop = unless rspush rspush BRANCH then
* limit start ?DO .. LOOP


currently implemented:
* BEGIN .. AGAIN
* n FOR .. NEXT
