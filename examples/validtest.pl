#!/usr/local/bin/perl

BEGIN { 
	$^W = 1;
}

use strict;
use CGI::FormMagick;
use Data::Dumper;

my $fm = new CGI::FormMagick(
	#DEBUG => 1
);

$fm->display();

sub colors {
 
    my $colors = ['red', 'blue', 'green', 'orange', 'purple', 'yellow'];
    return $colors;
}

# the post-event function for the FormMagick form. 
# takes a CGI::Persistent object as a parameter. 

sub test { return "foo" }

sub submit_form {
    my $cgi = shift;
    my @params = $cgi->param();

    print qq(<h2>This is my thingy</h2><p>What a nice thingy it is.</p>);

    # do what you want with the data we got in. 
    print "<ul>\n";
    foreach my $param (@params) {
	my $value =  $cgi->param($param);
	print "<li>$param: $value\n";
    }
    print "</ul>\n";

}

sub firstname {
	my $cgi = shift;
	
	return "Bob";
}
