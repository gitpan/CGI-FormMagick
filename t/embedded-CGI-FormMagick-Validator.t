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
#line 80 lib/CGI/FormMagick/Validator.pm
BEGIN: {
    use CGI::FormMagick;
    use CGI::FormMagick::Validator;
    use CGI;
    use vars qw($fm);
}
$fm = CGI::FormMagick->new(TYPE => 'FILE', SOURCE => 't/simple.xml');

}

{
#line 242 lib/CGI/FormMagick/Validator.pm
local $fm->{cgi};  # we're going to mess with the CGI fields

my $field = {
    VALIDATION =>  'nonblank',
    ID          => 'testfield',
    LABEL       => 'Test Field',
};

my $goodcgi = CGI->new( { testfield => 'testing' } );
$fm->{cgi} = $goodcgi;
is($fm->validate_field($field), "OK", "Test a single field");

my $badcgi  = CGI->new( { testfield => '' } );
$fm->{cgi} = $badcgi;
isnt($fm->validate_field($field), "OK", "Test a single field");

TODO: {
    local $TODO = "Make validate_field accept a fieldname instead of a fieldref";
    is($fm->validate_field("firstname"), "OK", "validate_field accepts field names");
}


}

{
#line 332 lib/CGI/FormMagick/Validator.pm

local $fm->{cgi} = CGI->new( { 
    firstname => 'testing',     # this is known-good
    lastname => '',             # bad. should be nonblank.
    long => "abc",              # bad. should be long.
    short => "abcdefghijk",     # bad. should be short.
} );

my @pagenames = ("Personal", "More", "More again");
foreach (0..2) {
    my %errors = $fm->validate_page($_);
    is(scalar keys %errors, $_, "Test page '$_' with $_ known errors");
    my %name_errors = $fm->validate_page($pagenames[$_]);
    is(scalar keys %name_errors, $_, "Test erroring page '$pagenames[$_]'");
}

$fm->{cgi} = CGI->new( { 
    firstname => 'willy',
    lastname => 'wonka',
    long => "abcdefg",
    short => "abc",
} );

foreach (@pagenames) {
    my %errors = $fm->validate_page($_);
    is(scalar keys %errors, 0, "Test page '$_' without errors");
}

ok(!defined $fm->validate_page("abcde"), "Validate page returns undef for a non-page");
ok(!defined $fm->validate_page(),        "Validate page returns undef no args");


}

{
#line 417 lib/CGI/FormMagick/Validator.pm

local $fm->{cgi} = CGI->new( { 
    firstname => 'testing',     # this is known-good
    lastname => '',             # bad. should be nonblank.
    long => "abc",              # bad. should be long.
    short => "abcdefghijk",     # bad. should be short.
} );

local $fm->{page_stack} = "0,1";
local $fm->{page_number} = 2;

my %errors = $fm->validate_all();
is(scalar keys %errors, 3, "Test all pages at once.");


}

{
#line 467 lib/CGI/FormMagick/Validator.pm
my @rv = $fm->parse_validation_routine("foo(1,2)");
is($rv[0], "foo", "Pick up validation routine name");
is($rv[1], "1,2", "Pick up validation routine args");

}

{
#line 504 lib/CGI/FormMagick/Validator.pm

sub user1 {
    return "OK";
}

is($fm->do_validation_routine("nonblank", "abc"), "OK", 
    "Find builtin validation routine");
is($fm->do_validation_routine("user1", "abc"), "OK", 
    "Find user validation routine");
{
    local $^W = 0;
    is($fm->do_validation_routine("nosuchthing", "abc"), "OK", 
        "Default to OK if you can't find a validation routine");
}


}

{
#line 551 lib/CGI/FormMagick/Validator.pm
sub usertest_ok {
    return "OK";
}

sub usertest_data {
    return shift;
}

sub usertest_arg1 {
    return $_[1];
}

sub usertest_arg2 {
    return $_[2];
}

is($fm->call_user_validation("usertest_ok",   "", ""),    "OK",
    "Call a simple user validation routine");
is($fm->call_user_validation("usertest_data", "FOO", ""), "FOO",
    "Call a user validation routine with data");
is($fm->call_user_validation("usertest_arg1", "", "bar"), "bar",
    "Call a user validation routine with one arg");
is($fm->call_user_validation("usertest_arg2", "", "bar,baz"), "baz",
    "Call a user validation routine with two args");


}

{
#line 599 lib/CGI/FormMagick/Validator.pm

is($fm->call_fm_validation("nonblank", "abc", ""),    "OK",
    "Call a simple builtin validation routine");
isnt($fm->call_fm_validation("nonblank", "", ""),    "OK",
    "Call a simple builtin validation routine");
is($fm->call_fm_validation("minlength", "abc", "2"),    "OK",
    "Call a builtin validation routine with args");
is($fm->call_fm_validation("lengthrange", "abc", "1,3"),    "OK",
    "Call a builtin validation routine with multiple args");


}

