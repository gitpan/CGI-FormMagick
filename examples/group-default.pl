#!/usr/bin/perl -wT

use strict;
use lib "../lib/";
use CGI::FormMagick;

my $fm = new CGI::FormMagick();

$fm->display();

sub post {
    my $cgi  = shift;
    my $colour = $cgi->param('colour');
    my $os     = $cgi->param('os');
    print qq(
        <h2>Results</h2>
        <p>Colour is $colour</p>
        <p>OS is $os</p>
    );
    return 1;
}

