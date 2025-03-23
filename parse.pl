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
inline: 2 byte

func: 3 + n*1
inline: n*2
breakeven: 3 times, saved: 4 times
breakeven:
w/align==2: 4 + n*1
inline:         n*2
breakeven 4, saved: 5

=cut

use v5.34;
use warnings;
no warnings qw(uninitialized experimental::smartmatch);

use Data::Dumper;

# set boolean constant DEBUG according to environment variable DEBUG
BEGIN {
	my $d = !!$ENV{DEBUG};
	*DEBUG = sub(){ $d };
}

my $contents = do { local $/; <> || die "read failed: $!" };
$contents =~ s/\\\s.*$//gm;
$contents =~ s/\(\s+[^)]*\)//gm;
my @stream = split ' ', $contents;
my $str = join " ",@stream;
$str =~ s/ :(\??) /\n:$1 /g;

my %defined = map { $_ => 1 } qw(doloop1 endloop1 do loop if then else);
my %seen;
# SOURCE=empty.fth bash viert3.asm 2>/dev/null |  sed -n '/^.*NEW DEFINITION: /s///p' | awk '{print$1}' | tr -d '"' | tr '\n' ' '
my %builtin = map { $_ => 1 } qw(EXIT over drop store fetch spfetch rpfetch nand not rspush zbranch branch while2 rdrop dotstr string plus divmod lit8 lit32 swap rot syscall3);
my %dep;
$dep{doloop1}{rspush}++;
$dep{endloop1}{while2}++;
$dep{endloop1}{rdrop}++;
$dep{if}{zbranch}++;
$dep{if}{branch}++;
$dep{else}{branch}++;
$dep{jump}{branch}++;
#my @filter = qw(1 - . 0= 1+ and bshift bye c dup emit false fiz2 inc mod negate nl puts signbit space true u.);
my @filter = qw(- 0= 1+ bye c doloop1 dup else emit endloop1 false fiz2 if inc mod negate nl puts space then true u. 1);

#my $filter = @filter;
my $filter = 1;


our $i = 0;

sub name {
	my $name = shift;
	given($name){
		s/@/fetch/;
		s/!/store/;
		s/\+/plus/;
		s/-/minus/;
		s/\./dot/;
		s/=/eq/;
		s/<>/ne/;
		s/>/to/;
		s/'/_/g;
		s/;/EXIT/g;
	}
	return $name;
}

sub dbg {
	print "._",name($_),"_$i:\t" if DEBUG;
}

my $optional = 0;
my $word;
while(scalar(@stream)){
	$i++;

	given(shift@stream){
		when(/^(doloop1|endloop1|do|loop|if|then|else)$/) {
			$dep{$word}{$_}++;
			dbg;
			say $_;
		}
		when(/^(dotstr|string|jump)$/) {
			$dep{$word}{$_}++;
			my $str = shift @stream;
			dbg;
			say "$_ $str";
		}
		when(':') {
			$word = shift @stream;
			my $name = name($word);
			$defined{$word}++;
			say "";
			if(!$filter || grep {$_ eq $word} @filter){
				$defined{$word}++;
				say "DEFFORTH \"$name\"";
				$optional = 0;
			}
			else {
				say "%if 0 ; $word";
				$optional = 1;
			}
		}
		when(':?') {
			$word = shift @stream;
			my $name = name($word);
			say "";
			if($builtin{$name}){
				say "%if 0 ; $word";
			}
			elsif(!$filter || grep {$_ eq $word} @filter){
				$defined{$word}++;
				say "%ifndef f_$name";
				say "DEFFORTH \"$name\"";
			}
			else {
				say "%if 0 ; $word";
			}
			$optional = 1;
		}
		when(/^-?\d+$/) {
			dbg;
			if($defined{$_} and $word ne $_){
				say STDERR "LITf $word $_";
				say "f_$_";
			}
			else{
				if($_ < 256 && $_ >= 0){
					$dep{$word}{lit8}++;
					say "f_lit8";
					say "db $_";
				}elsif($_ > 0xffffffff && $_ < -2147483648){
					$dep{$word}{lit64}++;
					say "f_lit64";
					say "dq $_";
				}else{
					$dep{$word}{lit32}++;
					say "f_lit32";
					say "dd $_";
				}
				say STDERR "LITn $word $_";
			}

		}
		when(";") {
			dbg;
			say "END";
			say "%endif" if $optional;
		}
		when(";NORETURN") {
			dbg;
			say "END no_next";
			say "%endif" if $optional;
		}
		when(/^'/) {
			dbg;
			say "lit ${_}";
		}
		when('MAIN') {
			$word = $_;
			say "";
			say "";
			say "A_FORTH:";
			say "FORTH:";
		}
		when(/^[A-Z]/) {
			dbg;
			# XXX fix
			if($_ eq "EXIT"){
				say "f_EXIT";
			}
			else {
				say STDERR "LITc $word $_";
				say "lit $_";
			}

		}
		default {
			dbg;
			my $name = name($_);
			say "f_$name";
			# prevent infinite recursion
			#TODO: mutually recursive words will probably break
			$dep{$word}{$_}++ if $_ ne $word;
			$seen{$name}++;
		}

	}
	

};

sub dp {
	say STDERR @_;
}

dp "SEEN:";
dp Dumper(\%seen);
#dp Dumper(\%builtin);

my %out;
sub recurse {
	my $name = shift;
	#dp "N: $name";
	for(keys %{$dep{$name}}){
		#dp "$_";
		$out{$_}++;
		recurse($_);
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
			die "UNKNOWN ",name($_)," ";
		}
	}
	else {
		dp $_;
		push @out, $_;
	}
}

say STDERR join$",@out;
say STDERR "BUILTIN:";
say STDERR join$/,sort map{name($_)}@b;

