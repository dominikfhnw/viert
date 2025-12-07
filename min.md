[1] M. Patel, ‘Vägen mot en minimal Forth arkitektur’, Linköping University, Linköping, Sweden, LiTH-IDA-R-90-02, Jan. 1990. Accessed: Nov. 29, 2025. [Online]. Available: https://github.com/larsbrinkhoff/forth-documents/blob/master/V%C3%A4gen%20mot%20en%20minimal%20Forth%20arkitektur.pdf
AIN


> Bernd Paysan
> 30.08.1996, 09:00:00
> an
> 
> Marc de Groot wrote:
> >
> > brad....@symbios.com wrote:
> > >
> > > I have used Forth for bringup on new machines before, and have often
> > > wondered what is the minimum word set required to be implemented in
> > > assembly language.
> >
> > About seven years ago I remember seeing a list of Forth primitives that
> > was claimed to be a minimum set. If I remember correctly, there were
> > seven of them.
> >
> > Was it Mikael Patel who posted that list? My memory is dim.
> 
> My name memory is dim, too. But I remember the words (and the implicit
> assumption that it's a threaded system with empty docol (everything is
> colon)):
> 
> SP@
> RP@
> @
> !
> + (or 2*)
> NAND
> 0=
> EXIT
> 
> Someone claimed that you can synthesize every logic operation out of
> NAND, but this is not true: you can't do left shifts (that's what + is
> for) and right shifts (that's what 0= is for).
> 
> I thought, on the original list there was LIT, but look:
> 
> : DUP SP@ @ ;
> : -1 ( x -- x 0 ) DUP DUP NAND DUP DUP NAND NAND ;
> : 1 -1 DUP + DUP NAND ;
> : 2 1 DUP + ;
> \ : 4 2 DUP + ; for 4 bytes/cell Forth
> : LIT RP@ @ 2 ( 4 ) + DUP RP@ ! @ ;
> 
> And now we can do real stuff, since we can define variables. Their body
> consists of LIT <address> EXIT.
> 
> Other important words:
> 
> : AND NAND DUP NAND ;
> 
> : BRANCH RP@ @ DUP @ + 2 + RP@ ! ;
> : ?BRANCH 0= RP@ @ @ AND RP@ @ + 2 + RP@ ! ;
> 
> I think it would be really interesting do do this to a real end (e.g.
> the 30 eForth primitives), and try this. Should be dammed slow!
> 
> BTW: RP! and SP! are done with looping, because you can either push or
> pop one element form these stacks per time. If you carefully save those
> parts you want to overwrite while processing, you can do it
> non-destructive (e.g. for a task switcher), as long as you don't
> overwrite the location that performs the RP! or SP! code ;-).
> 
> -- 
> Bernd Paysan

0001009e <A_plus2>:
   1009e:       58                      pop    eax
   1009f:       59                      pop    ecx
   100a0:       01 c8                   add    eax,ecx
   100a2:       eb f7                   jmp    1009b <pushA>


00010095 <A_nand>:
   10095:       58                      pop    eax
   10096:       5a                      pop    edx
   10097:       21 d0                   and    eax,edx
   10099:       f7 d0                   not    eax
   1009b:       eb f7                   jmp    1009b <pushA>



Minimal instructions:
* EXIT
* store
* fetch
* rpsp@
* sp@
* 2*
* nand
* (syscall)



> SP@
> RP@
-> replace with rp@sp@
   or is sp@rp@ better?
   N.b. our threading model allows jumping inside words, e.g. we can jump directly to the sp@ part
   rsdrop is part of EXIT, is it needed?
> @
> !
> + (or 2*)
-> 2* works badly, as it we will still need 0= if we use it
-> + works, but too big. 1+ also works!
> NAND
> 0=
-> muahahah, not needed.
: dup sp@ @ ;
: not dup nand ;
: and nand not ;
: negate not 1+ ;
: 0< 0x80000000 and ;
: or ( x y -- x|y ) not swap not nand ;
: 0= dup 0< swap negate 0< or ;
-> NOPE... puts too much requirements on ?branch to handle non-pure booleans
> EXIT

Final list:
* rp@sp@
* @
* !
* 1+
* NAND
* EXIT




LIT:
: lit32 rp@ @ dup CELL+ rp@ ! @ ;
: LIT   RP@ @ CELL+ DUP RP@ ! @ ;
