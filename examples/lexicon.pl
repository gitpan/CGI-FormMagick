#!/usr/bin/perl -wT 

use strict;
use lib "../lib";
use CGI::FormMagick;
use Data::Dumper;

my $fm = new CGI::FormMagick();

$fm->display();

sub say_hello {
    my $cgi  = shift;
    my $name = $cgi->param('name');
    my $greeting = $fm->localise("Hello") . ", $name";
    print qq(<h2>$greeting</h2>);
    return 1;
}

