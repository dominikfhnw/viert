# Small Forths, and some notes about them

## Jonesforth
* The original inspiration for this project
* Well written, literate program
* Not particularly optimized for size

## tokthr
* Nice ideas for a very small forth - both for the core AND programs based on it
* 8-bit Token threaded code, with a 16-bit lookup table
* Introduced the concept of a primitive/forth word break to me
* Code is a bit hard to read, especially the macros used for defining new words
* Unfinished

## eForth
* self-compiles
* Writeup: http://www.exemark.com/FORTH/eForthOverviewv5.pdf
* Kragen's writeup: https://dercuano.github.io/notes/eforth-notes.html, https://dercuano.github.io/notes/eforth86-notes.html

## StoneKnifeForth
* https://github.com/kragen/stoneknifeforth/
* Very small self-compiler

## sectorForth
* included code does not actually run on it (have to at least strip comments)
* Not particularly well size-optimized, despite its size

## milliForth
* Extremely small, 336 bytes for the core
* Golfed words. Their "not equal zero" word is 7 bytes, compared to my 9 byte attempt

## miniforth (https://compilercrim.es/bootstrap/miniforth/)
* You need to implement an assembler on top of it first to get conditionals/branches

## Tumble Forth
* Nice writeup/tutorial
* Not particularly optimized for size

## viert
* My humble entry
* Optimized for total size (core, basic words, user program) instead of just core size
* tethered Forth - words get defined at compile-time, not run-time
* Linux/x86
* 3 threading modes implemented (TODO: this changes a lot...):
  * token threading with 8-bit tokens
  * direct threading with 16-bit offset from a fixed base
  * direct threading with 8-bit scaled (1,2,4,8) offsets from a fixed base
    * this gives the smallest code size currently
  * all modes use a break for discerning primitive/forth words
