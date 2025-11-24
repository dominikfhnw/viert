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

NOINLINE triggers:
* EXIT at non-last position
* recursive function
* rp@ used in function (does not always need to be NOINLINE)
* ;CONTINUE

OPTIONS all over the place:
* -DBRANCH8=1 on cmdline
* LIT8 in parse.pl, LITSIZE In p2.pl
* immediate i in viert3.asm, codeword i in codewords.asm
* zbranch/nzbranch/zbranchc
* WORDSET, "\ ASM" pragma, ugly C_ macros everywhere (generate codewords.asm?)
* asm() statements in p2.pl being the new WORDSET
* INLINE/INLINEALL in p2.pl
* viert.sh: global envs vs -D... cmdline

=cut

use v5.34;
use warnings;
no warnings qw(uninitialized experimental::smartmatch);

use Scalar::Util qw(looks_like_number);
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

# set boolean constant DEBUG according to environment variable DEBUG
BEGIN {
	my $d = !!$ENV{DEBUG};
	*DEBUG = sub(){ $d };
}

sub dp {
	say STDERR @_;
}

sub dp2 {
	say STDERR @_ if 1;
}


sub opt {
	my $name = shift;
	my $env = $ENV{$name};
	if(not defined $env or $env eq ''){
		$env = shift;
	}
	warn "ENV $name $env\n";
	return $env;
}
my $WORD_ALIGN = opt "WORD_ALIGN", 1;
my $INLINE = opt "INLINE", 1;		# enable inlining
my $INLINEALL = opt "INLINEALL", 0;	# inline as much as possible
my $PRUNE = opt "PRUNE", 1;		# remove unused functions
my $ZBRANCHC = 0;			# use 'zbranchc' if true
my $BRANCH8 = 1;			# 
my $VARHELPER = 1;			# use varhelper function for variables
my $LIT8 = opt "LIT8", 1;		#
my $LIT = opt "LIT", "xlit32";		# which lit function to use
my $SMALLASM = opt "SMALLASM", 0;	# optimize for smallest asm
my $SCALED = opt "SCALED", 1;		# use 8bit scaled offsets?
my $OPT = opt "OPT", 0;
my $FORTHBRANCH = opt "FORTHBRANCH", 0;

if($SMALLASM){
	$BRANCH8 = 0;
	$LIT8 = 0;
}
my $WORD_SIZE = 4;
$WORD_SIZE = 1 if $SCALED;

dp "OPT $OPT PRUNE $PRUNE INLINEALL $INLINEALL SMALLASM $SMALLASM SCALED $SCALED";

my %word;
my %dep2;

my $CONTINUE = "";
my $LASTWORD = "";
my %builtin_all = map { $_ => 1 } qw(
	0< 1+ 1- EXIT bye divmod drop dup @ i < - nand not over + rp@ rpsp@ rsinci rspush sp@ !
	swap 2*
	stringr string dotstr string0
	rsdrop
	if else unless do swapdo loop loople begin again until notuntil next
	syscall3_noret syscall3
	syscall7
	dupemit
	lit32
	varhelper

); 
#	syscall3_noret syscall3

# if/unless: zbranch/nzbranch
# else: branch
# do: swap rspush
# swapdo: rspush
# loop: j/rp@/rpsp@....
# begin: -
# again: branch
# until/notuntil: zbranch/nzbranch/(not)
# 
# string stringr dotstr 
# unless if then endif branch else do swapdo loop loople begin again until notuntil i next
my %noinline;
my %alwaysinline;
#rsinc i j rsinci rspush rflip 
my %asmabstract = map { $_ => 1 } qw(lit8 lit32 branch zbranch nzbranch zbranchc stringr);
my @comment = qw(

	divmod u. rp@

	not dup negate true false rp@ and drop pos1 pos3
	over pos1
);
my %baseline = map { $_ => 1 } qw(! @ EXIT nand sp@);
my %codeword = map { $_ => 1 } qw();
my %inline = (
	#true		=>	[-1],
	#false		=>	[0],
	STDOUT		=>	[1],
	SYS_exit	=>	[1],
	SYS_write	=>	[4],
	CELL_SIZE	=>	[4],
	'CELL_SIZE*1'	=>	[4],
	'CELL_SIZE*2'	=>	[8],
	'CELL_SIZE*3'	=>	[12],
);

my @wordorder = ();

sub getstream {
	my $contents = do { local $/; <> || die "read failed: $!" };
	$contents =~ s/\(\s+[^)]*\)//gm;		# ( comments )
	$contents =~ s/\\\s.*$//gm;			# \ comments
	$contents =~ s/:x\s+[^;]*\;(NORETURN)?//gm;	# ":x": disabled words
	return split ' ', $contents;
}

# TODO: refactor/delete
#sub isneeded {
#	my $name = shift;
#	if(exists $builtin{$name}){
#		#dp "NOTNEEDED $name";
#		return 0;
#	}
#	else {
#		#dp "NEEDED $name";
#		return 1;
#	}
#}
sub noinline {
	my $name = shift;
	$noinline{$name}++;
}

sub alwaysinline {
	my $name = shift;
	$alwaysinline{$name}++;
}


sub hlparse {
	my @stream = @_;
	my $word = "MAIN";
	while(scalar(@stream)){

		given(shift@stream){
			#dp "TOK $_";
			when('variable'){
				$word = shift @stream;
				push @wordorder, $word;
				#$LASTWORD = $word;
				# XXX layering violation - this is the optimizer.
				# See also comment below for the words that look like numbers
				$word{$word} = ["VARIABLE","EXIT"];
				push @{ $word{$word} }, "varhelper" if $VARHELPER;
				if($CONTINUE){
					die "continue is illegal before variable";
				}
			}
			when(':') {
				$word = shift @stream;
				push @wordorder, $word;
				$LASTWORD = $word;
				$word{$word} = [];
				if($CONTINUE){
					dp "CONTINUE AGAIN $CONTINUE $word";
					push @{ $word{$CONTINUE} }, $word;
					push @{ $word{$CONTINUE} }, "CONTINUE";
					$noinline{$word}++;
					#$dep2{$CONTINUE}{$word}++;
					undef $CONTINUE;
				}
			}
			when(':?') {
				$word = shift @stream;
				push @wordorder, $word;
				$LASTWORD = $word;
				$word{$word} = ["MAYBE"];
				die "optional word after ;CONTINUE: $CONTINUE -> $_" if $CONTINUE;
			}
			when(";") {
				#$dep2{$word}{EXIT}++;
				push @{ $word{$word} }, "EXIT";
				$word = "MAIN";
			}
			when(";CONTINUE") {
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
			when('NOINLINE') {
				noinline $word;
			}
			when('ALWAYSINLINE') {
				alwaysinline $word;
			}
			when('recurse') {
				push @{ $word{$word} }, $word;
				#$dep2{$word}{$_}++;
			}
			# XXX TODO this should not be in the parser that should be factored out from this file anyway
			# looks like a number and is not defined yet:
			when(/^(-?\d+|0x[a-fA-F0-9]+|'.*')$/ && !$word{$_}) {
				push @{ $word{$word} }, $_;
				my $lit = $LIT;
				if($LIT8 && looks_like_number($_) && $_ >= 0 && $_ < 256){
					$lit = "lit8";
				}
				$word{$_} = ['LITERAL',$lit];
			}
			# XXX same caveat as above
			when('asm') {
				my $asm = shift @stream;
				$asm =~ s/(^"|"$)//g;
				$codeword{$asm}++;
				dp "ASM pragma: $asm";
			}
			default {
				push @{ $word{$word} }, $_;
				#$dep2{$word}{$_}++;
			}
		}
	}
}

hlparse(getstream());
#push @wordorder, "MAIN";
#dp Dumper(\@wordorder);
#dp Dumper(\%dep2);

my %reach;
sub reachable {
	if(!$PRUNE){
		for my $name (keys %word){
			$reach{$name}++;
			foreach(@{ $word{$name} }){
				$reach{$_}++;
				# autovivification
				$word{$_} = [] unless exists $word{$_};
			}
		}
		return
	}
	my $name = shift;
	$reach{$name}++;
	dp "R $name";
	foreach(@{ $word{$name} }){
		$reach{$_}++;
		if($reach{$_} == 1){
			reachable($_);
		}
		# TODO: needed?
	}
}

my %count;
sub countusage {
	foreach my $name (sort keys %word){
		if($reach{$name}){
			foreach(@{ $word{$name} }){
				$count{$_}++;
			}
		}
	}
}

sub removeunreachable {
	foreach my $name (sort keys %word){
		unless($reach{$name}){
			dp "DELETE unreach $name";
			delete $word{$name} if $PRUNE;
		}
		if($codeword{$name}){
			dp "DELETE codeword $name";
			delete $word{$name};
		}
	}
}

#dp Dumper(\%dep2);
#my %inline;

sub inline {
	my @word = @_;
	my $orig = pop @word;
	#if($word[-1] eq "CONTINUE"){
	#	warn "inline tried in CONTINUE word ",join(" ",@word);
	#}
	my @out;
	foreach my $word (@word) {
		# do not inline our own definition if the current word is recursive
		if(exists $inline{$word} && $word ne $orig){
			dp "INLINE $word";
			push @out, @{ $inline{$word} };
		}
		else {
			push @out, $word;
		}
		#dp "inl ",join(" ",@out);
	}
	return @out;
}

sub asm {
	my $name = shift;
	if($reach{$name}){
		$codeword{$name}++;
		dp "ASM reach $name"; 
		# TODO: better way?
		#$LIT8 = 1 if $name eq "lit8";
	}
	elsif($asmabstract{$name}){
		$codeword{$name}++;
		dp "ASM abstract $name"; 
		# TODO: better way?
		#$LIT8 = 1 if $name eq "lit8";
	}
	else {
		#$codeword{$name}++;
		dp "ASM UNREACHABLE $name"; 
	}
}

sub is_inlineable {
	return 0 unless $INLINE;
	my $name = shift;
	dp "IS_INLINEABLE early $name";
	# TODO: can happen if @wordorder is not updated. Needed?
	return 0 unless exists $word{$name};
	# do not inline words where we already decided that we need the asm version
	return if $codeword{$name};
	return if $noinline{$name};
	dp "IS_INLINEABLE firstpass $name";

	my $count = $count{$name};
	my @word = inline(@{$word{$name}},$name);
	my @orig = @{$word{$name}};
	my $len0 = scalar(@word) * $WORD_SIZE;
	if($word[0] eq "VARIABLE"){
		return 0;
	}
	if($word[0] eq "MAYBE"){
		shift @word;
	}
	if($word[-1] eq "EXIT"){
		pop @word;
	}
	if($orig[0] eq "MAYBE"){
		shift @orig;
	}
	my $litsize = 0;
	my $escape = $name;
	$escape =~ s/([?.+-])/\\$1/g;
	for(@word){
		if(defined($word{$_})){
			my @inner = @{ $word{$_} };
			if($inner[0] eq "LITERAL"){
				my $type = $inner[1];
				if($type eq "lit8"){
					$litsize += 1;
				} elsif($type eq "lit32"){
					$litsize += 4;
				} elsif($type eq "xlit8"){
					$litsize += 1;
				} elsif($type eq "xlit32"){
					$litsize += 4;
				} else {
					die "unknown littype $type in $_";
				}
				dp "LITERAL inline $type -> $litsize";
			}
		}
		if(/^(EXIT|rp@|CONTINUE|rpsp@|$escape)$/){
			$_="(SELF)" if $_ eq $name;
			dp "NOT_INLINEABLE $name: no, has $_\tX:",join(" ",@word);
			return 0;
		}
	}
	$len0 += $litsize;

	dp "INL COUNT $name len:$len0/",scalar(@word) * $WORD_SIZE;
	my $len1 = scalar(@word) * $WORD_SIZE + $litsize;
	#if($len1 == 1){
	#	dp "IS_ALIAS: $name";
	#	return 1;
	#}
	my $sorig = $len0 + $count * $WORD_SIZE;
	my $sinline = $count * $len1;
	dp "IS_INLINEABLE $name count:$count len0:$len0 len1:$len1 ldif:",($len0-$len1)," sorig:$sorig sinline:$sinline \tX:",join(" ",@word)," origX:",join(" ",@orig);

	if($sorig == $sinline){
		dp "\tinline neutral $sorig == $sinline";
		return 1;
	}elsif($sorig > $sinline){
		dp "\tinline smaller $sorig > $sinline";
		return 1;
	}else{
		dp "\tinline bigger $sorig < $sinline";
		return $INLINEALL;
	}
}

#dp "USED:";
sub prepare_inline {
	for(@wordorder){
		# inlining active, word appears exactly once, is not excluded
		#if($INLINE && exists $word{$_} && $count{$_} == 1 && !$noinline{$_}){
		if(is_inlineable($_)){
			#dp "INLINE? $_";
			my @word = @{ $word{$_} };
			if($word[0] eq "MAYBE"){
				shift @word;
			}
			if($word[-1] eq "EXIT"){
				pop @word;
			}
			# apply already known inlines
			#dp "SINGLE0 $_ ", join(" ", @word);
			@word = inline(@word,$_);
			$inline{$_} = \@word;
			#dp "SINGLE $_ ", join(" ", @word);
		}
	}
}
sub inline_all {
	foreach my $word (keys %word){
		if($word eq "xxxxxxx"){
			dp "SSSS SKIP $word";
			next;
		}
		my @word = @{ $word{$word} };

		my @out = inline(@word,$word);

		$word{$word} = \@out;
	}
}

#dp Dumper(\%word);

reachable "MAIN";
# mark drop as reachable if we have zbranchc
# TODO: what if zbranchc only defined later?
reachable "drop" if $ZBRANCHC;
# XXX TODO XXX
reachable "xzbranch";
reachable "xbranch";
reachable "drop";

if(!$PRUNE){
	asm "rpsp@"; # resolve circular definitions
	asm "syscall3"; # resolve circular definitions
}

sub smallprog {
	asm "divmod";
	asm "swap";
	asm "drop";
	asm "-";
	asm "i";
	asm "not";
	asm "rp@";
	asm "rsinc";
}

if($OPT == 0){
	# generic, but often bigger program than if options are chosen by hand
	# some harder decisions:
	# syscall3 vs syscall3_noret
	# use syscall3_noret if syscall3 is only used in :? syscall3_noret
	# use bye if syscall3/syscall3_noret is only used in :? bye
	# rsinc vs rsinci
	# zbranchc/nzbranch/zbranch
	# lit8/lit32: nasm expanding lits is insane. Otherwise just "hard"
	#		to choose between lit8/lit32
	# minus: not always worth it
	#asm "lit32"; # XXX TEMP 

	asm "2*"; # XXX ploos testing
	asm "rp@"; # XXX ploos testing
	my %gg;
	if($reach{'syscall7'}){
		%gg = (
			unless		=> "nzbranch",
			if		=> "zbranch,branch",
			notuntil	=> "nzbranch",
			until		=> "zbranch,branch",
			print		=> "stringr,lit8",
			stringr		=> "lit8",
			#dup		=> "dup",
			#"1+"		=> "1+",
			#"2*"		=> "2*",
		);
	}
	else{
		%gg = (
			unless		=> "nzbranch",
			if		=> "zbranch,branch",
			notuntil	=> "nzbranch",
			until		=> "zbranch,branch",
			syscall3	=> "syscall3",
			syscall3_noret	=> "syscall3_noret",
			print		=> "stringr,lit8",
			stringr		=> "lit8",
			#dup		=> "dup",
			#"1+"		=> "1+",
			#"2*"		=> "2*",
		);
	}
	for(sort keys %gg){
		dp "findauto $_";
		if($reach{$_}){
			dp "AUTO asm $_ $gg{$_}";
			for(split/,/,$gg{$_}){
				asm $_;
			}
		}
	}

	if(!$SMALLASM){
		smallprog();
	}
	else {
		asm "rpsp@";
	}

}
elsif($OPT == 1){
	# fib3
	#smallprog();	
	
	asm "divmod";
	asm "syscall3_noret";
	asm "-";
	asm "swap";
	asm "dup";
	asm "drop";
	asm "1-";
	asm "<";
}
elsif($OPT == 2){
	# fizz8
	asm "syscall3_noret";

	# smaller overall size, but more asm
	if(!$SMALLASM){
		asm "divmod";
		asm "swap";
		asm "drop";
		asm "-";
		asm "i";
		asm "1+";
		asm "not";
		asm "rsinc";
		asm "rp@";
	}
	else {
		$ZBRANCHC = 1;
		asm "rpsp@";
	}
}
elsif($OPT == 3){
	# fizz9
	asm "nzbranch";
	asm "syscall3_noret";

	if(!$SMALLASM){
		asm "divmod";
		asm "drop";
		asm "rsinci";
		asm "not";
		asm "i";
	}
	else {
		asm "rpsp@";
	}
}
elsif($OPT == 4){
	# fizz9b
	asm "syscall3_noret";
	#asm "0<>";
	asm "0<";
	asm "0=";
	asm "2*";
	asm "branch";
	asm "zbranch";

	if(!$SMALLASM){
		asm "divmod";
		asm "drop";
		asm "rsinci";
		asm "not";
		asm "i";
	}
	else {
		$ZBRANCHC = 1;
		asm "rpsp@";
		asm "lit32";
	}
	$LIT8 = 0;
	$ZBRANCHC = 0;
}
elsif($OPT == 5){
	delete $codeword{"branch"};
	delete $codeword{"zbranch"};
	asm "rpsp@"; # resolve circular definitions
	asm "syscall3"; # resolve circular definitions
	#asm "0<>";
	asm "0<";
	asm "lit32";
	#asm "bye";
}
elsif($OPT == 6){ # bggp6.fth
	dp "OPT6";
	#asm "lit32"; # XXX TEMP 
	my %gg = (
		unless		=> "nzbranch",
		if		=> "zbranch",
		notuntil	=> "nzbranch",
		until		=> "zbranch",
		syscall3	=> "syscall3",
		syscall3_noret	=> "syscall3_noret",
		print		=> "stringr,lit8",
		stringr		=> "lit8",
	);
	for(keys %gg){
		dp "findauto $_";
		if($reach{$_}){
			dp "AUTO asm $_ $gg{$_}";
			for(split/,/,$gg{$_}){
				#asm $_;
			}
		}
	}
	#smallprog();
	asm "divmod";
	#asm "swap";
	asm "drop";
	#asm "-";
	#asm "i";
	#asm "not";
	asm "rp@";
	#asm "rsinc";
	asm "syscall3_noret";

}
else{
	die "unknown OPT $OPT";
}

dp "CWxx";
dp Dumper(\%codeword);
asm "zbranchc" if $ZBRANCHC;
asm "lit8" if $LIT8;
# which words are reachable from main?
reachable "MAIN";
# mark drop as reachable if we have zbranchc
reachable "drop" if $ZBRANCHC;
#reachable "not" if $NOTUNTILZBRANCHC;
# remove everything which can not be reached
removeunreachable();
# TODO: function to remove words already covered by codewords
# count how many time each word that is reachable is called
countusage;

dp "COUNT333";
dp Dumper(\%count);
dp Dumper(\%word);
# mark codewords

###my @b = qw(syscall3_noret syscall3);
#foreach(@b){
#	$codeword{$_}=1 if $count{$_};
#}

for(sort keys %baseline){
	if(exists $word{$_}){
		dp "BUILTIN1? $_";
		$codeword{$_}++;
	}
}

for(sort keys %builtin_all){
	if(exists $word{$_} && scalar@{$word{$_}} == 0 ){
		dp "BUILTIN? $_ ",scalar@{$word{$_}};
		$codeword{$_}++;
	}
}

dp "CODEWORD";
dp Dumper(\%codeword);

# prepare substitution list for all 1-count words
prepare_inline();
# substitute all words in the substitution list with their expansion
inline_all();
# TODO: inline_func("dup");

dp "AFTER INLINE";
dp Dumper(\%codeword);
# remove unreachable after inline
undef %reach;
reachable "MAIN";
# mark drop as reachable if we have zbranchc
reachable "drop" if $ZBRANCHC;
#reachable "not" if $NOTUNTILZBRANCHC;
#dp Dumper(\%word);
removeunreachable();

#dp "COUNT:";
#dp Dumper(\%count);

undef %count;
countusage;

dp "COUNT2:";
dp Dumper(\%count);
dp Dumper(\%word);

prepare_inline();
# substitute all words in the substitution list with their expansion
inline_all();

undef %reach;
reachable "MAIN";
# mark drop as reachable if we have zbranchc
reachable "drop" if $ZBRANCHC;
#dp Dumper(\%word);
removeunreachable();

# TODO: proper check if all codewords are still needed after all the pruning and inlining
if($reach{'EXIT'}){
	dp "EXIT reachable";
}
else {
	dp "EXIT unreachable";
	delete $codeword{'EXIT'};
}

for(sort keys %codeword){
	if($reach{$_}){
		#dp "CODEWORD final: $_ reachable";
	}
	else {
		if($asmabstract{$_}){
			dp "CODEWORD unreach: $_ abstract";
		}
		else {
			dp "CODEWORD unreach: $_ normal";
			delete $codeword{$_};
		}
		#delete $codeword{'EXIT'};
	}
}


dp "COUNT3:";
dp Dumper(\%count);
dp Dumper(\%word);

###############################################################
## now it's just turning all data structures into text again
###############################################################

my $abranch = "branch";
my $branch = "zbranch";
$branch = "zbranchc" if $ZBRANCHC;
$branch = "nzbranch" if $codeword{"nzbranch"};
$branch = "xzbranch" if $FORTHBRANCH;
$abranch = "xbranch" if $FORTHBRANCH;

dp "AFTER INLINE";
dp Dumper(\%codeword);
open my $fh, ">", "wordset.asm";
for(sort keys %codeword){
	s/@/fetch/;
	s/!/store/;
	s/\+/plus/;
	s/\*/mul/;
	s/-/minus/;
	s/=/eq/;
	s/if/$branch/;
	s/unless/$branch/;
	s/else/$abranch/;
	s/again/$abranch/;
	s/<>/ne/;
	s/</lt/;
	say $fh "%define C_$_" or die "err $!";
	#dp "wordset: %define C_$_";
}
close $fh;

say '\ / 2>&-;	# I\'m also a bash script';
my $opt = "-DWORD_ALIGN=$WORD_ALIGN -DBRANCH8=$BRANCH8 -DSCALED=$SCALED";
say '\ / 2>&-;	RUN= DIS=1 LIT8='.$LIT8.' LIT="'.$LIT.'" SOURCE=$0 ./viert.sh '.$opt.' "$@"; exit $?';

say "\\ ASM ",join(",", sort keys %codeword);

dp "REHYD";

sub rehydrate2 {
	my $name = shift;
	if(not defined $word{$name}){
		die "uhoh: word $name not found";
	}

	my @word = @{ $word{$name}};

	if($word[0] eq "MAYBE"){
		shift @word;
		if($codeword{$name}){
			dp "word $name builtin";
			return 0;
		}
	}
	return \@word;
}

sub rehydrate {
	my $name = shift;
	my @word = @{ rehydrate2($name) || return "" };

	if($word[0] eq "VARIABLE"){
		return "variable $name";
	}
	if($word[-1] eq "EXIT"){
		$word[-1] = ";";
	}
	elsif($word[-1] eq "CONTINUE"){
		pop @word;
		pop @word;
		push @word, ";CONTINUE";
	}
	else {
		push @word, ";NORETURN";
	}

	my $out = ": $name ". join(" ", @word);
	return $out;
}


for my $word (@wordorder) {
	if(not exists $word{$word}){
		#dp "optimized away: $word";
	}
	else {
		my $out = rehydrate($word);
		say $out if $out ne "";
	}
}
dp "REHYD2";
say "MAIN";
#dp "XXXXXX";
#dp Dumper(\%word);
say join(" ",@{ rehydrate2("MAIN") });

exit;

