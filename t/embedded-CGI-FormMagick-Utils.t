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
#line 37 lib/CGI/FormMagick/Utils.pm

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
#line 72 lib/CGI/FormMagick/Utils.pm
is($fm->get_page_by_name('Personal'), 0, "get page by name");

}

{
#line 93 lib/CGI/FormMagick/Utils.pm
is(ref($fm->get_page_by_number(0)), 'HASH', "get page by number");

}

{
#line 148 lib/CGI/FormMagick/Utils.pm
ok(defined($fm->parse_template), "Fail gracefully if no template");

}

{
#line 175 lib/CGI/FormMagick/Utils.pm
my $form = $fm->form();
is(ref $form, "HASH", "form data structure is a hash");

}

{
#line 192 lib/CGI/FormMagick/Utils.pm
my $page = $fm->page();
is(ref $page, "HASH", "page data structure is a hash");

}

