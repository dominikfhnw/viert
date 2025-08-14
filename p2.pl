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

#my %defined; # = map { $_ => 1 } qw(do loop if unless then endif else);
my %word;
my %dep2;

my $CONTINUE = "";
my $LASTWORD = "";
my %builtin_all = map { $_ => 1 } qw(0< 1- EXIT branch bye divmod drop dup @ i iloop inext lit32 lit8 < - nand not nzbranch over plus rp@ rpsp@ rsinci rspush sp@ ! stringr swap syscall3 xzbranch zbranch);
my %builtin = map { $_ => 1 } qw(0< EXIT divmod drop @ inext lit32 lit8 nand not over plus rp@ rspush sp@ ! swap syscall3 zbranch branch);
my %noinline = map { $_ => 1 } qw(rsinc i rsinci);

my @wordorder = ();

sub getstream {
	my $contents = do { local $/; <> || die "read failed: $!" };
	$contents =~ s/\\\s.*$//gm;
	$contents =~ s/\(\s+[^)]*\)//gm;
	$contents =~ s/:x\s+[^;]*\;(NORETURN)?//gm;
	return split ' ', $contents;
}

sub dp {
	say STDERR @_;
}

sub dp2 {
	say STDERR @_ if 1;
}

sub isneeded {
	my $name = shift;
	if(exists $builtin{$name}){
		#dp "NOTNEEDED $name";
		return 0;
	}
	else {
		#dp "NEEDED $name";
		return 1;
	}
}

sub hlparse {
	my @stream = @_;
	my $word = "MAIN";
	while(scalar(@stream)){

		given(shift@stream){
			#dp "TOK $_";
			when(':') {
				$word = shift @stream;
				push @wordorder, $word;
				$word{$word} = [];
				#$defined{$word}++;
				$LASTWORD = $word;
				if($CONTINUE){
					dp "CONTINUE AGAIN $CONTINUE $word";
					$dep2{$CONTINUE}{$word}++;
					undef $CONTINUE;
				}
			}
			when(':?') {
				$word = shift @stream;
				push @wordorder, $word;
				$word{$word} = ["MAYBE"];
				die "optional word after ;CONTINUE: $CONTINUE -> $_" if $CONTINUE;
				#$defined{$word}++;
				$LASTWORD = $word;
			}
			when(";") {
				$dep2{$word}{EXIT}++;
				push @{ $word{$word} }, "EXIT";
				$word = "MAIN";
			}
			when(";CONTINUE") {
				dp "CCCCCCC";
				$CONTINUE = $LASTWORD;
			}
			when(";NORETURN") {
				$word = "MAIN";
			}
			when('MAIN') {
				$word = $_;
			}
			when('ENDPARSE') {
				return;
			}
			default {
				push @{ $word{$word} }, "$_";
				$dep2{$word}{$_}++;
				#dp "RRRRRRRRRRRR $word -> $_: $dep2{$word}{$_}";
			}
		}
	}
}

hlparse(getstream());
#push @wordorder, "MAIN";
#dp Dumper(\@wordorder);
dp Dumper(\%dep2);

my %used;
sub recurse2 {
	my $name = shift;
	my $nest = shift || 0;
	#dp2 "\t"x$nest, "$name";
	$nest++;
	for(keys %{$dep2{$name}}){
		my $count = $dep2{$name}{$_};
		$used{$_} += $count;
		#dp2 "\t"x$nest, "$_ MIAU";
		if($_ ne $name and isneeded($_)){
			recurse2($_,$nest);
		}
		#recurse2($_,$nest) if $_ ne $name and isneeded($_);
	}
}
recurse2 "MAIN";
$used{"MAIN"} = 666;

dp Dumper(\%dep2);
my %inline;

sub inline {
	my @word = @_;
	my @out;
	foreach my $word (@word) {
		if(1 && exists $inline{$word}){
			dp "INLINE $word";
			push @out, @{ $inline{$word} };
		}
		else {
			push @out, $word;
		}
	}
	return @out;
}


sub rehydrate2 {
	my $name = shift;
	if(not exists $word{$name}){
		die "uhoh: word $name not found";
	}

	if(not defined $word{$name}){
		dp "word $name optimized away";
		return 0;
	}

	my @word = @{ $word{$name}};

	if($word[0] eq "MAYBE"){
		shift @word;
		if($builtin{$name}){
			dp "word $name builtin";
			return 0;
		}
	}

	my @out = inline(@word);
	
	#my $out = join(" ", @out);
	return \@out;
}

sub rehydrate {
	my $name = shift;
	my @word = @{ rehydrate2($name) || return "" };

	if($word[-1] eq "EXIT"){
		$word[-1] = ";";
	}
	else {
		push @word, ";CONTINUE";
	}

	my $out = ": $name ". join(" ", @word);
	dp "AAA $name $out";
	return $out;
}

dp "USED:";
for(@wordorder){
	#dp "USECHECK $_";
	if($used{$_} == 1 && !$noinline{$_}){
		my @word = @{ $word{$_} };
		if($word[0] eq "MAYBE"){
			shift @word;
		}
		if($word[-1] eq "EXIT"){
			pop @word;
		}
		@word = inline(@word);
		$inline{$_} = \@word;
		dp "SINGLE $_ ", join(" ", @word);
		# the key will still exist, but with value undef
		#undef $word{$_};
	}
}
dp Dumper(\%inline);


say '\               # I\'m also a bash script';
say '\ / 2>&-;       RUN= DIS=1 SOURCE=$0 ./viert.sh -DWORD_ALIGN=1 "$@" -DWORDSET=4; exit $?';

# TODO: merge with for loop above? $noinline{} used twice
for my $word (@wordorder) {
	if($used{$word} == 1 && !$noinline{$word}){
		dp "optimized away: $word";
	}
	elsif($used{$word}){
		#dp "WORD $word used";
		my $out = rehydrate($word);
		say $out if $out ne "";
	}
	else {
		#dp "\\ WORD $word unused";
	}
}
say "MAIN";
dp "XXXXXX";
dp Dumper(\%word);
say join(" ",@{ rehydrate2("MAIN") });

exit;

__END__
#############################################################################
#############################################################################
#############################################################################
#############################################################################
#############################################################################
#############################################################################
#############################################################################
#############################################################################
#############################################################################
#############################################################################
#############################################################################

our $i = 0;
my %dep;
#my %seen;
# SOURCE=empty.fth bash viert3.asm 2>/dev/null |  sed -n '/^.*NEW DEFINITION: /s///p' | awk '{print$1}' | tr -d '"' | tr '\n' ' '
#my %builtin = map { $_ => 1 } qw(rsinc rsdup i rspop EXIT int3 over drop store fetch spfetch rpfetch nand not rspush zbranch nzbranch branch while2 rdrop dotstr string stringr plus divmod lit8 lit32 swap rot syscall3);
# XXX external swap, over, drop
my %builtin = map { $_ => 1 } qw(for next begin again while rsdup rspop EXIT int3 store fetch spfetch xrpspfetch nand not zbranch nzbranch branch while2 rdrop dotstr string stringr plus lit8 lit32 syscall3);

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

#my $filter = @filter;
my $filter = 0;

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
			#dp2 "TOK $_";
			when(/^(for|next|begin|again|until|notuntil|swapdo|do|loop|loople|if|unless|then|endif|else)$/) {
				$dep{$word}{$_}++;
				dbg;
				say $_;
			}
			when(/^(dotstr|string|stringr|jump)$/) {
				$dep{$word}{$_}++;
				my $str = shift @stream;
				dbg;
				say "$_ $str";
			}
			#when(/^(lit)$/) {
			#	dbg;
			#	my $str = shift @stream;
			#	say "lit $str";
			#}
			when(':') {
				$word = shift @stream;
				$word{$word} = [];
				my $name = name($word);
				#dp2 "WORD $name";
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
				$word{$word} = ["MAYBE"];
				my $name = name($word);
				#dp2 "WORD $name";
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
				#dp2 "NUM? $_";
				$_ = hex if /^0x/;
				dbg;
				if($defined{$_} and $word ne $_){
					$dep{$word}{$_}++;
					say STDERR "LITf $word $_";
					say "f_$_";
				}
				else{
					if($LIT8 && $_ < 256 && $_ >= 0){
						$dep{$word}{lit8}++;
						say "f_lit8";
						say "db $_";
						say STDERR "LIT8 $word $_";
						#push @{ $word{$word} }, "f_lit8";
					}elsif($_ > 0xffffffff && $_ < -2147483648){
						$dep{$word}{lit64}++;
						say "f_lit64";
						say "dq $_";
						say STDERR "LIT64 $word $_";
						#push @{ $word{$word} }, "f_lit64";
						#push @{ $word{$word} }, "dq $_";
					}else{
						$dep{$word}{lit32}++;
						say "f_lit32";
						say "dd $_";
						say STDERR "LIT32 $word $_";
						#push @{ $word{$word} }, "f_lit32";
						#push @{ $word{$word} }, "dd $_";
					}
				}

			}
			when(";") {
				#dp2 "COLON";
				dbg;
				$dep{$word}{EXIT}++;
				say "END";
				say "%endif" if $optional;
			}
			when(";CONTINUE") {
				dbg;
				$CONTINUE = $LASTWORD;
				#dp2 "CONTINUE $_";
				say "END no_next";
				say "%endif" if $optional;
			}
			when(";NORETURN") {
				#dp2 "COLON NORET";
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
				}
				else {
					say STDERR "LITc $word $_";
					$dep{$word}{litc}++;
					say "lit $_";
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
		recurse($_,$nest) if $_ ne $name;
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
