#!/usr/local/bin/perl -w

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

my $xml = qq(
  <FORM TITLE="FormMagick demo application" POST-EVENT="submit_order">
    <PAGE NAME="Personal" TITLE="Personal details" POST-EVENT="lookup_group_info">
      <FIELD ID="firstname" LABEL="first name" TYPE="TEXT" VALIDATION="nonblank"/>
      <FIELD ID="lastname" LABEL="last name" TYPE="TEXT" VALIDATION="nonblank"/>
    </PAGE>
  </FORM>
);

ok($fm = CGI::FormMagick->new(TYPE => 'STRING', SOURCE => $xml), "create fm object");


}

{
#line 73 lib/CGI/FormMagick/Setup.pm
TODO: {
    local $TODO = "writeme";
    fail();
}

}

{
#line 131 lib/CGI/FormMagick/Setup.pm
is(ref($fm->{clean_xml}), "HASH", "clean_xml gives us a hash");
is($fm->{clean_xml}->{TITLE}, "FormMagick demo application", "Picked up form title");
is(ref($fm->{clean_xml}->{PAGES}), "ARRAY", "clean_xml gives us an array of pages");
is(ref($fm->{clean_xml}->{PAGES}->[0]), "HASH", "each page is a hashref");
is($fm->{clean_xml}->{PAGES}->[0]->{NAME}, "Personal", "Picked up first page's name");
is(ref($fm->{clean_xml}->{PAGES}->[0]->{FIELDS}), "ARRAY", "Page's fields are an array");

}

{
#line 172 lib/CGI/FormMagick/Setup.pm
ok( CGI::FormMagick::initialise_sessiondir("abc"), "Initialise sessiondir with name");
ok( CGI::FormMagick::initialise_sessiondir(),      "Initialise sessiondir with undef");

}

