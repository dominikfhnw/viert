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
if(0){
	say STDERR $str;
	say STDERR "";
	say STDERR "";
}

my %known;
my %visited;

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

my $optional = 0;
my $word;
our $i = 0;
sub dbg {
	print "._",name($_),"_$i:\t" if DEBUG;
}
while(scalar(@stream)){
	$i++;

	given(shift@stream){
		when(/^(doloop1|endloop1|do|loop|if|then|else|jump)$/) {
			dbg;
			say $_;
		}
		when(/^(dotstr|string).?$/) {
			my $str = shift @stream;
			dbg;
			say "$_ $str";
		}
		when(':') {
			my $name = name(shift @stream);
			$known{$name}++;
			#say STDERR "WORD $name";
			$word = $name;
			say "";
			say "DEFFORTH \"$name\"";
			$optional = 0;
		}
		when(':?') {
			my $name = name(shift @stream);
			$known{$name}++;
			#say STDERR "WORD $name";
			$word = $name;
			say "";
			say "";
			say "%ifndef f_$name";
			say "DEFFORTH \"$name\"";
			$optional = 1;
		}
		when(/^-?\d+$/) {
			dbg;
			if($known{$_} and $word ne $_){
				say STDERR "LITf $word $_";
				say "f_$_";
			}
			else{
				say STDERR "LITn $word $_";
				say "lit $_";
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
			if($name =~ /^(if|else|then|endloop1|doloop1)$/){
				say "$name";
			}
			elsif($name =~ /^(jump)$/){
				say "$name ", shift @stream;
			}
			else {
				say "f_$name";
				$visited{$name}++;
			}
		}

	}
	

};

say STDERR Dumper(\%visited);
say STDERR Dumper(\%known);
