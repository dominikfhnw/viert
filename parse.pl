#!/usr/bin/perl
use v5.34;
use warnings;
no warnings qw(uninitialized experimental::smartmatch);

use Data::Dumper;

my $contents = do { local $/; <> || die "read failed: $!" };
$contents =~ s/\\\s.*$//gm;
$contents =~ s/\(\s+[^)]*\)//g;
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
		s/=/eq/;
		s/<>/ne/;
	}
	return $name;
}

my $optional = 0;
while(scalar(@stream)){

	given(shift@stream){
		when(/^(doloop1|endloop1|if|then|else|jump)$/) {
			say $_;
		}
		when('string') {
			my $str = name(shift @stream);
			say "string $str";
		}
		when(':') {
			my $name = name(shift @stream);
			$known{$name}++;
			say "";
			say "DEFFORTH \"$name\"";
			$optional = 0;
		}
		when(':?') {
			my $name = name(shift @stream);
			say "";
			say "%ifndef f_$name";
			say "DEFFORTH \"$name\"";
			$optional = 1;
		}
		when(/^-?\d+$/) {
			say "lit $_";
		}
		when(";") {
			say "END";
			say "%endif" if $optional;
		}
		when(/^'/) {
			say "lit ${_}";
		}
		when('MAIN') {
			say "A_FORTH:";
			say "FORTH:";
		}
		when(/^[A-Z]/) {
			# XXX fix
			if($_ eq "EXIT"){
				say "f_EXIT";
			}
			else {
				say "lit $_";
			}

		}
		default {
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
