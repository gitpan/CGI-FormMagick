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
#line 31 lib/CGI/FormMagick/HTML.pm
BEGIN: {
        use_ok('CGI::FormMagick');
        use vars qw($fm $i);
        use lib "lib/";
}

my $xml = qq(
  <FORM TITLE="FormMagick demo application" POST-EVENT="submit_order">
  <PAGE NAME="Personal" TITLE="Personal details" POST-EVENT="lookup_group_info">
  <FIELD ID="firstname" LABEL="first name" TYPE="TEXT" VALIDATION="nonblank"/>
  </PAGE>
  </FORM>
);

$fm = new CGI::FormMagick(TYPE => 'STRING', SOURCE => $xml);


}

{
#line 250 lib/CGI/FormMagick/HTML.pm
my $f = {			# minimalist fieldinfo hashref
	VALIDATION => 'foo',
	LABEL => 'bar',
	TYPE => 'TEXT',
	ID => 'baz'
};

$fm->{cgi} = CGI::new->("");

ok(($i = $fm->gather_field_info($f)), "Gather field info");
ok(ref($i) eq 'HASH', "gather_field_info returning a hashref");


}

{
#line 300 lib/CGI/FormMagick/HTML.pm
ok(my $if = $fm->build_inputfield($i, CGI::FormMagick::TagMaker->new()), "build input field");

}

