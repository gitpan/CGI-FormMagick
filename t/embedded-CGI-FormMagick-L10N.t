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
#line 87 lib/CGI/FormMagick/L10N.pm
BEGIN: {
    use_ok('CGI::FormMagick');
    use vars qw($fm);
    use lib "./lib";
}

$ENV{HTTP_ACCEPT_LANGUAGE} = $ENV{LANG} = $ENV{LANGUAGE} = "fr";

my $xml = qq(
  <FORM TITLE="FormMagick demo application" POST-EVENT="submit_order">
    <PAGE NAME="Personal" TITLE="Personal details" POST-EVENT="lookup_group_info">
      <FIELD ID="firstname" LABEL="first name" TYPE="TEXT" VALIDATION="nonblank"/>
    </PAGE>
  </FORM>
);

ok ($fm = new CGI::FormMagick(TYPE => 'STRING', SOURCE => $xml), "created fm object");

ok( $fm->add_lexicon("fr", { "yes" => "oui" })     , "Simple add_lexicon");
ok( not($fm->add_lexicon("fr", "abc" ))  , "Non-hashref lexicon should fail");
ok( not($fm->add_lexicon("fr", (1,2,3))) , "Non-hashref lexicon should fail");
ok( not($fm->add_lexicon("fr", [1,2,3])) , "Non-hashref lexicon should fail");
TODO: {
	local $TODO = "Haven't yet implemented tests for non-existent languages";
	ok( not($fm->add_lexicon("xx", { yes => 'oui' }))     , "Non-existent language should fail");
}


}

{
#line 160 lib/CGI/FormMagick/L10N.pm
is($fm->localise("yes"), "oui", "Simple localisation");
is($fm->localise("xyz"), "xyz", "Attempted localisation of untranslated string");
is($fm->localise(""),    "",    "Fail gracefully on localisation of empty string");

}

