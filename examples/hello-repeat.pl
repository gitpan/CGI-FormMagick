#!/usr/bin/perl -wT

use strict;
use lib "../lib/";
use CGI::FormMagick;

my $fm = new CGI::FormMagick( DEBUG => 1);

$fm->display();

sub say_hello {
    my $cgi     = shift;
    my $name    = $cgi->param('name');
    my $howmany = $cgi->param('howmany');
    print "<h2>Hello, $name</h2>\n" x $howmany;
    return 1;
}

