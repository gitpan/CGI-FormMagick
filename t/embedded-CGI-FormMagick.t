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
#line 143 lib/CGI/FormMagick.pm
BEGIN: {
    use_ok('CGI::FormMagick');
    use vars qw($fm);
    use lib "lib/";
}

my $xml = qq(
  <FORM TITLE="FormMagick demo application" POST-EVENT="submit_order">
    <PAGE NAME="Personal" TITLE="Personal details" POST-EVENT="lookup_group_info">
      <FIELD ID="firstname" LABEL="first name" TYPE="TEXT" VALIDATION="nonblank"/>
      <FIELD ID="lastname" LABEL="last name" TYPE="TEXT" VALIDATION="nonblank"/>
    </PAGE>
  </FORM>
);

ok(CGI::FormMagick->can('new'), "We can call new");
ok($fm = CGI::FormMagick->new(TYPE => 'STRING', SOURCE => $xml), "create fm object"); 
ok($fm->isa('CGI::FormMagick'), "fm object is what we expect");


}

{
#line 204 lib/CGI/FormMagick.pm
ok($fm->display(), "Display");

}

{
#line 509 lib/CGI/FormMagick.pm
TODO: {
    local $TODO = "writeme";
    ok($fm->get_option_labels_and_values($f), "get option labels and values");
    ok($fm->get_option_labels_and_values($f), "fail gracefully with empty/no options attribute");
}

}

