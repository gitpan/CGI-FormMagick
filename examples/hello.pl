#!/usr/bin/perl -wT 

use strict;
use lib "../lib";
use CGI::FormMagick;

my $fm = new CGI::FormMagick();

$fm->display();

sub say_hello {
    my $cgi  = shift;
    my $name = $cgi->param('name');
    print qq(
        <h2>Hello, $name</h2>
        <p>It is moderately nice to meet you.</p>
    );
    return 1;
}

