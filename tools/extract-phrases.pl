#!/usr/local/bin/perl

use strict;
use XML::Parser;

my $x = new XML::Parser (Style => 'Tree');
my $xml = $x->parsefile($ARGV[0]);

$\ = "\n";				# output record separator

print $xml->[1][0]->{TITLE};		# form title

# page titles and descriptions
for (my $p = 4; $p < scalar(@{$xml->[1]}); $p += 4) { 
	my $page = $xml->[1][$p][0];
	print $page->{TITLE};
	print $page->{DESCRIPTION} if $page->{DESCRIPTON};
	for (my $f=4; $f <= scalar (@{$xml->[1][$p]}); $f += 4) {
		my $field = $xml->[1][$p][$f][0];
		print $field->{LABEL};
		print $field->{DESCRIPTION} if $field->{DESCRIPTION};
		print $field->{VALIDATION_ERROR_MESSAGE} if $field->{VALIDATION_ERROR_MESSAGE};
	}
}






