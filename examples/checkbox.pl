#!/usr/bin/perl -w

use strict;
use lib "../lib";
use CGI::FormMagick;

my $fm = new CGI::FormMagick();

$fm->display();

sub done {
    my $cgi  = shift;
    my $fries   = $cgi->param('fries');
    my $ketchup = $cgi->param('ketchup');
    my $hat     = $cgi->param('hat');
    my $shoes   = $cgi->param('shoes');
    my $gloves  = $cgi->param('gloves');
    print qq(
        <h2>Here are the results</h2>
        <pre>
        Fries           $fries
        Ketchup         $ketchup
        Hat             $hat
        Shoes           $shoes
        Gloves          $gloves
        </pre>
    );
    return 1;
}

