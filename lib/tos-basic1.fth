:? not dup nand ;
: invert not ;
: and nand not ;
: imply not nand ;
: droptrue dup imply ;
:? dropfalse droptrue not ;
:? drop droptrue and ;
