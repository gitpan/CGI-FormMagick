#!/usr/bin/perl -w

open (A, $ARGV[0]) or die "Couldn't open $ARGV[0]: $!";
open (B, $ARGV[1]) or die "Couldn't open $ARGV[1]: $!";

while (my $a = <A> and my $b = <B>) {
	print "$a$b\n";
}
