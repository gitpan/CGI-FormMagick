#!perl -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
    my($class) = shift;
    return bless {}, $class;
}

sub PRINT  {
    my($self) = shift;
    $main::_STDOUT_ .= join '', @_;
}

sub READ {}
sub READLINE {}
sub GETC {}

package main;

local $SIG{__WARN__} = sub { $_STDERR_ .= join '', @_ };
tie *STDOUT, 'Catch' or die $!;


{
#line 52 lib/CGI/FormMagick/TagMaker.pm
TODO: {
    local $TODO = "Write tests for TagMaker!";
    ok(0, "Fake test just to keep 'make test' happy");
}

}

{
#line 231 lib/CGI/FormMagick/TagMaker.pm
BEGIN: { 
    use_ok('CGI::FormMagick::TagMaker'); 
}
my $t = CGI::FormMagick::TagMaker->new();
isa_ok($t, 'CGI::FormMagick::TagMaker');

}

