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
#line 36 lib/CGI/FormMagick/Setup.pm

BEGIN: {
    use vars qw( $fm );
    use lib "./lib";
    use CGI::FormMagick;
}

ok($fm = CGI::FormMagick->new(TYPE => 'FILE', SOURCE => "t/simple.xml"), "create fm object");


}

{
#line 90 lib/CGI/FormMagick/Setup.pm
is(ref($fm->{xml}), "HASH", "parse_xml gives us a hash");
is($fm->{xml}->{TITLE}, "FormMagick demo application", 
    "Picked up form title");
is(ref($fm->{xml}->{PAGES}), "ARRAY", 
    "parse_xml gives us an array of pages");
is(ref($fm->{xml}->{PAGES}->[0]), "HASH", 
    "each page is a hashref");
is($fm->{xml}->{PAGES}->[0]->{NAME}, "Personal", 
    "Picked up first page's name");
is($fm->{xml}->{PAGES}->[0]->{TITLE}, "Personal details", 
    "Picked up first page's title");
is(ref($fm->{xml}->{PAGES}->[0]->{FIELDS}), "ARRAY", 
    "Page's fields are an array");
is(ref($fm->{xml}->{PAGES}->[0]->{FIELDS}->[0]), "HASH", 
    "Field is a hashref");
is($fm->{xml}->{PAGES}->[0]->{FIELDS}->[0]->{LABEL}, "first name", 
    "Picked up field title");
is($fm->{xml}{PAGES}[0]{FIELDS}[0]{DESCRIPTION}, "description here", 
    "Picked up field description");

}

{
#line 221 lib/CGI/FormMagick/Setup.pm
ok( CGI::FormMagick::initialise_sessiondir("abc"), "Initialise sessiondir with name");
ok( CGI::FormMagick::initialise_sessiondir(),      "Initialise sessiondir with undef");

}

