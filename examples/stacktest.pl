#!/usr/local/bin/perl -w

use strict;
use CGI::FormMagick;

my $fm = new CGI::FormMagick(
	DEBUG => 1
);

$fm->display();

sub gotopage {
	my $cgi = shift;
	my $wherenext = "Page" . $cgi->param("gotopage");
	$cgi->param(-name => "wherenext", -value => $wherenext);
	return 1;
}

