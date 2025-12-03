#!/usr/bin/perl
my $LIT8	= $ENV{'LIT8'} // 1;
my $LIT		= $ENV{'LIT'} // "xlit32"; # which lit function to use
my $VARHELPER	= $ENV{'VARHELPER'} // 1; # use varhelper function to create smaller variables?

use v5.34;
use warnings;
no warnings qw(uninitialized experimental::smartmatch);

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

my %defined;
my %word;

my $CONTINUE = "";
my $LASTWORD = "";

our $i = 0;

sub f {
	return 'f "'.shift().'"';
}

sub dp {
	say STDERR @_;
}

sub dp2 {
	say STDERR @_ if 0;
}

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
				dbg;
				say $_;
			}
			when(/^(dotstr|string|stringr|string0|jump|print|xlit32)$/) {
				my $str = shift @stream;
				dbg;
				say "$_ $str";
			}
			when(/^(variable)$/) {
				$word = shift @stream;
				my $name = name($word);
				dp2 "VARIABLE $name";
				say "";
				$defined{$word}++;
				$LASTWORD = $word;
				say "DEFFORTH \"$name\"";
				if($VARHELPER){
					say f("varhelper");
					say "END no_next";
				}
				else {
					say f($LIT);
					say "dd ${name}_mem";
					say "END";
				}
				say "${name}_mem:";
				say "dd 0";
				if($CONTINUE){
					die "continue not legal before variable";
				}
			}
			when(':') {
				$word = shift @stream;
				my $name = name($word);
				dp2 "WORD $name";
				say "";
				$defined{$word}++;
				$LASTWORD = $word;
				say "DEFFORTH \"$name\"";
				if($CONTINUE){
					dp "CONTINUE AGAIN $CONTINUE $name $_";
					undef $CONTINUE
				}
				$optional = 0;
			}
			when(':?') {
				$word = shift @stream;
				my $name = name($word);
				dp2 "WORD $name";
				say "";
				die "optional word after ;CONTINUE: $CONTINUE -> $_" if $CONTINUE;
				$defined{$word}++;
				$LASTWORD = $word;
				say "%ifndef ".f($name);
				say "DEFFORTH \"$name\"";
				$optional = 1;
			}
			when(/^(-?\d+$|0x[a-fA-F0-9]+)/) {
				dp2 "NUM? $_";
				$_ = hex if /^0x/;
				dbg;
				if($defined{$_} and $word ne $_){
					say STDERR "LITf $word $_";
					say f(name($_));
				}
				else{
					if($LIT8 && $_ < 256 && $_ >= 0){
						say f("lit8");
						say "db $_";
						say STDERR "LIT8 $word $_";
					}elsif($_ > 0xffffffff && $_ < -2147483648){
						say f("lit64");
						say "dq $_";
						say STDERR "LIT64 $word $_";
					}else{
						say f($LIT);
						say "dd $_";
						say STDERR "LIT32 $LIT $word $_";
					}
				}

			}
			when(";") {
				dp2 "COLON";
				dbg;
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
			#when(/^'/) {
			#	dbg;
			#	say "lit ${_}";
			#}
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
			default {
				dbg;
				my $name = name($_);
				say f($name);
			}
		}
	}
}

parse(@stream);
