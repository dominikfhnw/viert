This is a mess right now, best to not look at it.
Very, very much in the prototyping stage.

* A very small forth interpreter, for Linux, x86 assembler.
* ELF executable is about 512 bytes right now
* 3 threading modes implemented:
** token threading with 8-bit tokens
** direct threading with 16-bit offset from a fixed base
** direct threading with 8-bit scaled (1,2,4,8) offsets from a fixed base
