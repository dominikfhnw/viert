:? not dup nand ;
: invert not ;
: and nand not ;
: imply not nand ;
#if !TOS_ENABLE
: dropfalse droptrue not ;
#endif
: droptrue dropfalse not ;
:? drop droptrue and ;
