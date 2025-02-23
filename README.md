This is a mess right now, best to not look at it.
Very, very much in the prototyping stage.

* A very small forth interpreter, for Linux, x86 assembler.
* ELF executable is about 512 bytes right now
  * linked with ld at the moment. Custom ELF header would be -40 bytes
* 3 threading modes implemented:
  * token threading with 8-bit tokens
  * direct threading with 16-bit offset from a fixed base
  * direct threading with 8-bit scaled (1,2,4,8) offsets from a fixed base
    * this gives the smallest code size currently
* Inspirations:
  * Jonesforth (https://rwmj.wordpress.com/2010/08/07/jonesforth-git-repository/)
  * Kragen's tokthr (https://github.com/kragen/tokthr/)
  * Kragen's mailing list, Kragen's random hackernews comments I found while
    searching for various topics...
