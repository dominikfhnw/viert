#!/usr/bin/perl
=pod

TODO: SYS_exit/SYS_write are broken for 64bit!

Some ideas/improvements:

* better string handling (whitespace)
* parse whole words as a stream of tokens, this allows us to:
* recognize single token words as aliases
* inline words only used once, or if inlining takes the same amount of bytes
* define new words for all literals. Seldom used literals then get inlined again
* inline if word alignment gives us free bytes
* optimizer?
* true as lit64 takes a lot of space, 'false not' is smaller
* bshift instead of lit for some cases?
* special handling for all 3 byte words? create them on startup?

const func:
3 bytes: lit8 <val> EXIT
inline: 2 byte (lit8 <val>)

called n times:
(align 1 or 3)
func: 3 + n*1 (3 byte func, 1 byte call)
inline:   n*2 (2 byte value)
breakeven: 3 times, saved: 4 times
breakeven:
w/align==2: 4 + n*1
inline:         n*2
breakeven 4, saved: 5

=cut
my $LIT8 = $ENV{'LIT8'} // 1;


use v5.34;
use warnings;
no warnings qw(uninitialized experimental::smartmatch);

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

# set boolean constant DEBUG according to environment variable DEBUG
BEGIN {
	my $d = !!$ENV{DEBUG};
	*DEBUG = sub(){ $d };
}

my $contents = do { local $/; <> || die "read failed: $!" };
$contents =~ s/\\\s.*$//gm;
$contents =~ s/\(\s+[^)]*\)//gm;
$contents =~ s/:x\s+[^;]*\;(NORETURN)?//gm;
my @stream = split ' ', $contents;
my $str = join " ",@stream;
$str =~ s/ :(\??) /\n:$1 /g;

my %defined;# = map { $_ => 1 } qw(do loop if unless then endif else);
#my %seen;
# SOURCE=empty.fth bash viert3.asm 2>/dev/null |  sed -n '/^.*NEW DEFINITION: /s///p' | awk '{print$1}' | tr -d '"' | tr '\n' ' '
#my %builtin = map { $_ => 1 } qw(rsinc rsdup i rspop EXIT int3 over drop store fetch spfetch rpfetch nand not rspush zbranch nzbranch branch while2 rdrop dotstr string stringr plus divmod lit8 lit32 swap rot syscall3);
# XXX external swap, over, drop
my %builtin = map { $_ => 1 } qw(for next begin again while rsdup rspop EXIT int3 store fetch spfetch xrpspfetch nand not zbranch nzbranch branch while2 rdrop dotstr string stringr lit8 lit32 syscall3 syscall3_noret);
my %word;
my %dep;
$dep{doloop1}{rspush}++;
$dep{endloop1}{while2}++;
$dep{endloop1}{rdrop}++;
$dep{loop}{branch}++;
$dep{if}{zbranch}++;
$dep{if}{branch}++;
$dep{unless}{zbranch}++;
$dep{unless}{branch}++;
$dep{else}{branch}++;
$dep{jump}{branch}++;
#my @filter = qw(1 - . 0= 1+ and bshift bye c dup emit false fiz2 inc mod negate nl puts signbit space true u.);
#my @filter = qw(- 0= 1+ bye c doloop1 dup else emit endloop1 false fiz2 if inc mod negate nl puts space then true u. 1);
#my @filter = qw(emit4b - 0= 1+ bye c doloop1 dup else emit endloop1 false fiz2 if inc mod negate nl space then true u. 1);
#my @filter = qw(- 0= 1+ bye c doloop1 dup else emit emit4b emitx endloop1 false fiz2 if inc mod negate nl then true u.);
#my @filter = qw(- c doloop1 else emit emit4b emitx endloop1 if then endif u. unless);

#my $filter = @filter;
my $filter = 0;

my $CONTINUE = "";
my $LASTWORD = "";

our $i = 0;

sub dp {
	say STDERR @_;
}

sub dp2 {
	say STDERR @_ if 0;
}

#my %alias = (
#	"false"	=>	"0",
#	"-1"	=>	"true",
#);
sub name {
	my $name = shift;
	given($name){
		s/@/fetch/;
		s/!/store/;
		s/\+/plus/;
		s/\*/mul/;
		s/-/minus/;
		s/\./dot/;
		s/=/eq/;
		s/<>/ne/;
		s/</lt/;
		s/>/gt/;
		s/'/_/g;
		s/:/dcol/g;
		s/;/EXIT/g;
	}
	return $name;
}

sub dbg {
	my $name = name($_);
	$name =~ y/*/x/;
	print "._",$name,"_$i:\t" if DEBUG;
}

sub parse {
	my @stream = @_;
	my $optional = 0;
	my $word = "MAIN";
	while(scalar(@stream)){
		$i++;

		given(shift@stream){
			dp2 "TOK $_";
			when(/^(for|next|begin|again|until|notuntil|swapdo|do|loop|loople|if|unless|then|endif|else)$/) {
				$dep{$word}{$_}++;
				dbg;
				say $_;
				push @{ $word{$word} }, $_;
			}
			when(/^(dotstr|string|stringr|jump|print|xlit32)$/) {
				$dep{$word}{$_}++;
				my $str = shift @stream;
				dbg;
				say "$_ $str";
				push @{ $word{$word} }, $_;
				push @{ $word{$word} }, $str;
			}
			#when(/^(lit)$/) {
			#	dbg;
			#	my $str = shift @stream;
			#	say "lit $str";
			#}
			when(/^(variable)$/) {
				$word = shift @stream;
				$word{$word} = [];
				my $name = name($word);
				dp2 "VARIABLE $name";
				#$defined{$word}++;
				say "";
				$defined{$word}++;
				$LASTWORD = $word;
				say "DEFFORTH \"$name\"";
				say "\tf_lit32";
				say "\tdd ${name}_mem";
				say "\tEND";
				say "${name}_mem:";
				say "dd 0";
				if($CONTINUE){
					die "continue not legal before variable";
				}
			}
			when(':') {
				$word = shift @stream;
				$word{$word} = [];
				my $name = name($word);
				dp2 "WORD $name";
				#$defined{$word}++;
				say "";
				$defined{$word}++;
				$LASTWORD = $word;
				say "DEFFORTH \"$name\"";
				if($CONTINUE){
					dp "CONTINUE AGAIN $CONTINUE $name $_";
					$dep{$CONTINUE}{$name}++;
					undef $CONTINUE
				}
				$optional = 0;
			}
			when(':?') {
				$word = shift @stream;
				$word{$word} = [];
				my $name = name($word);
				dp2 "WORD $name";
				say "";
				die "optional word after ;CONTINUE: $CONTINUE -> $_" if $CONTINUE;
				#if($builtin{$name}){
				#	say "%if 0 ; BUILTIN OVERRIDE $word";
				#}
				$defined{$word}++;
				$LASTWORD = $word;
				say "%ifndef f_$name";
				say "DEFFORTH \"$name\"";
				$optional = 1;
			}
			when(/^(-?\d+$|0x[a-fA-F0-9]+)/) {
				dp2 "NUM? $_";
				$_ = hex if /^0x/;
				dbg;
				if($defined{$_} and $word ne $_){
					$dep{$word}{$_}++;
					say STDERR "LITf $word $_";
					say "f_".name($_);
					push @{ $word{$word} }, "$_";
				}
				else{
					if($LIT8 && $_ < 256 && $_ >= 0){
						$dep{$word}{lit8}++;
						say "f_lit8";
						say "db $_";
						say STDERR "LIT8 $word $_";
						#push @{ $word{$word} }, "f_lit8";
						push @{ $word{$word} }, "$_";
					}elsif($_ > 0xffffffff && $_ < -2147483648){
						$dep{$word}{lit64}++;
						say "f_lit64";
						say "dq $_";
						say STDERR "LIT64 $word $_";
						#push @{ $word{$word} }, "f_lit64";
						#push @{ $word{$word} }, "dq $_";
						push @{ $word{$word} }, "$_";
					}else{
						$dep{$word}{lit32}++;
						say "f_lit32";
						say "dd $_";
						say STDERR "LIT32 $word $_";
						#push @{ $word{$word} }, "f_lit32";
						#push @{ $word{$word} }, "dd $_";
						push @{ $word{$word} }, "$_";
					}
				}

			}
			when(";") {
				dp2 "COLON";
				dbg;
				$dep{$word}{EXIT}++;
				push @{ $word{$word} }, "EXIT";
				say "END";
				say "%endif" if $optional;
			}
			when(";CONTINUE") {
				dbg;
				$CONTINUE = $LASTWORD;
				dp2 "CONTINUE $_";
				say "END no_next";
				say "%endif" if $optional;
			}
			when(";NORETURN") {
				dp2 "COLON NORET";
				dbg;
				say "END no_next";
				say "%endif" if $optional;
			}
			when(/^'/) {
				dbg;
				say "lit ${_}";
				push @{ $word{$word} }, "${_}";
			}
			when('MAIN') {
				$word = $_;
				say "";
				say "";
				say "A_MAIN:";
				say "FORTH:";
			}
			when('ENDPARSE') {
				dp "ENDPARSE";
				return;
			}
			when(/^[A-Z]/) {
				dbg;
				# XXX fix
				#if($defined{$_}){
				if($_ eq "EXIT"){
					say "f_EXIT";
					push @{ $word{$word} }, "EXIT";
				}
				else {
					say STDERR "LITc $word $_";
					$dep{$word}{litc}++;
					say "lit $_";
					push @{ $word{$word} }, "${_}";
				}

			}
			default {
				dbg;
				my $name = name($_);
				#dp "F $name $_ $alias{$name} in $word";
				#if($alias{$name}){
				#	dp "ALIAS $name $alias{$name}";
				#	$name = $alias{$name};
				#}

				#if($defined{$name}){
				if(1){
					push @{ $word{$word} }, "$_";
					say "f_$name";
					# prevent infinite recursion
					#TODO: mutually recursive words will probably break
					#$dep{$word}{$_}++ if $_ ne $word;
					$dep{$word}{$_}++;
					if($_ ne $word){
						#$dep{$word}{$_}++
					}else{
						dp "RRRRRRRRRRRRRRRRRRR $_";
					}
					#$seen{$name}++;
				}else{
					dp "LITc $word $_";
					say "lit $_";
				}
			}
		}
	}
}

parse(@stream);

#dp "SEEN:";
#foreach my $name (reverse sort { $seen{$a} <=> $seen{$b} } sort keys %seen) {
#	dp "$name\t$seen{$name}";
#}

#dp Dumper(\%seen);
#dp "ALIAS:";
#dp Dumper(\%alias);
#dp Dumper(\%builtin);

sub dbgword {
	my $name = shift;
	if($word{$name}){
		return join(",",@{ $word{$name} });
	}
	else {
		return "";
	}

}

my %out;
sub recurse {
	my $name = shift;
	my $nest = shift || 0;
	dp2 "\t"x$nest, "$name ", dbgword($name);
	$nest++;
	for(keys %{$dep{$name}}){
		my $count = $dep{$name}{$_};
		#$out{$_} += $count;
		$out{$_}++;
		#dp2 "\t"x$nest, "$name: $_ +$count = $out{$_}";
		recurse($_,$nest) if $_ ne $name and $out{$_} == 1;
	}
}
recurse "MAIN";

my @out;
my @b;
dp "";
dp "UNIQ:";
for(sort keys %out){
	if(!$defined{$_}){
		my $name = name($_);
		if($builtin{$name}){
			say STDERR "BUILTIN $_";
			push @b, $_;
		}
		else {
			warn "UNKNOWN ",name($_)," ",$_;
		}
	}
	else {
		dp $_;
		push @out, $_;
	}
}

dp "UNUSED:";
for(sort keys %defined){
	if(!$out{$_}){
		my $name = name($_);
		warn "UNUSED\t",name($_)," (",$_,")\n";
	}
	else {
		#dp $_;
	}
}

#say STDERR "JOINED OUT:";
#say STDERR join$",@out;
#say STDERR "BUILTIN:";
#say STDERR join$/,sort map{name($_)}@b;

say STDERR Dumper(\%out);
say STDERR Dumper(\%dep);
say STDERR Dumper(\%word);
