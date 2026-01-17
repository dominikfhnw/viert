# viert Forth compiler

This is the first kind-of "release" of my little forth compiler, specifically for BGGP6 (http://binary.golf/6).

Doing a full writeup for how this compiler works, especially one day before the deadline, is impossible.

Only so much: Forth is a programming language which is said to create very small executables. I tried various Forth implementations, and was sorely disappointed.

This project is my own take at creating a Forth compiler which is mainly optimized for creating very small standalone binaries.

## BGGP entry

This Forth program implements BGGP 4,5 and 6. It is based off my assembler entry (see https://github.com/dominikfhnw/bggp6-writeup/tree/main/allinone for that writeup).

Source code is in `bggp6.fth`. A precompiled version (154 bytes) is available as `bggp6-elf`. Minified sources are available under `minified.fth`.

To compile the program, you'll need:
* nasm
* perl

To compile the regular source file:
```
bash bggp6.fth
```
It will compile the program and run it under strace. Please note that *it will kill your shell* if you run it stand-alone, as part of implementing BGGP4. It gets safely executed under `strace` when you run it like above.

To compile the minified source file:
```
rm -rf ./6 && LIT8=1 ASM="i swap dup" FULL= TOS_ENABLE=0 ./optim.sh minified.fth
```

The full minified sources are
``` Forth
: s syscall3 ;
: z string0 ;
rdrop i 5 s 0 54 sp@ 8 s 187 s 64 s 6 swap 37 s 0 z "6l.al" z "-L" dup sp@ 0 swap z "/bin/curl" 11 s
```

Both should produce the exact same output, minified is just a lot less readable. The minified forth file was created from the `f2` artifact from the optimizer.
