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
#line 123 lib/CGI/FormMagick.pm
BEGIN: {
    use_ok('CGI::FormMagick');
    use vars qw($fm);
    use lib "lib/";
}

ok(CGI::FormMagick->can('new'), "We can call new");
ok($fm = CGI::FormMagick->new(TYPE => 'FILE', SOURCE => "t/simple.xml"), "create fm object"); 
isa_ok($fm, 'CGI::FormMagick');


}

{
#line 203 lib/CGI/FormMagick.pm

is($fm->previousbutton, 1, "Previous button set on to begin with");
$fm->previousbutton(0);
is($fm->previousbutton, 0, "Previous button turned off");
$fm->previousbutton(1);
is($fm->previousbutton, 1, "Previous button turned on again");
$fm->previousbutton("");
is($fm->previousbutton, 0, "Previous button turned off with empty string");
$fm->previousbutton("a");
is($fm->previousbutton, 1, "Previous button turned on with true string");

is($fm->debug, 0, "Debug set off to begin with");
$fm->debug(1);
is($fm->debug, 1, "Debug turned on");
$fm->debug(0);


}

{
#line 261 lib/CGI/FormMagick.pm

like($fm->sessiondir, qr(/session-tokens/), "Session dir set on to begin with");
$fm->sessiondir("/tmp");
is($fm->sessiondir, "/tmp", "Session dir changed");
$fm->sessiondir(0);
like($fm->sessiondir, qr(/session-tokens/), "Session dir returned to default");


}

{
#line 290 lib/CGI/FormMagick.pm
SKIP: {
    skip "Problems with CGI::Persistent", 1 unless 0;
    ok($fm->display(), "Display");
}

}

{
#line 688 lib/CGI/FormMagick.pm

use CGI;

$cgi = CGI->new({ wherenext => "foo" });
local $fm->{cgi} = $cgi;
is($fm->magic_wherenext(), "foo", "Found magic wherenext value");


}

{
#line 713 lib/CGI/FormMagick.pm

#
# First we test what happens when the user clicks Next normally.
#

local $fm->{page_number} = 0;
local $fm->{page_stack}  = "";
local $fm->{cgi} = CGI->new({
    firstname => "Kirrily",    # this should validate successfully.
    Next      => 1,
}); 

$fm->prepare_for_next_page();
is($fm->{page_number}, 1, "Increment the page number when user clicks next");
is($fm->{page_stack}, 0, "Set page stack when user clicks next");

#
# Now we're going to see what happens when the user just hits Enter
#

local $fm->{page_number} = 0;
local $fm->{page_stack}  = "";
local $fm->{cgi} = CGI->new({
    firstname => "Kirrily",
}); 

$fm->prepare_for_next_page();
is($fm->{page_number}, 1, "Increment the page number when user presses enter");
is($fm->{page_stack}, 0, "Set page stack when user presses enter");

#
# What if there's a magic "wherenext" value set?
#

local $fm->{page_number} = 0;
local $fm->{page_stack}  = "";
local $fm->{cgi} = CGI->new({
    firstname => "Kirrily",
    wherenext => "More again",
});  

$fm->prepare_for_next_page();
is($fm->{page_number}, 2, "Branch when magic wherenext is set");
is($fm->{page_stack}, 0, "Set page stack when magic wherenext is set");


}

{
#line 790 lib/CGI/FormMagick.pm
TODO: {
    local $TODO = "writeme";
    local $^W = 0; # Until these tests are happy
    ok($fm->get_option_labels_and_values($f), "get option labels and values");
    ok($fm->get_option_labels_and_values($f), "fail gracefully with empty/no options attribute");
}

}

{
#line 889 lib/CGI/FormMagick.pm

sub one  {
    return 1;
}

sub zero {
    return 0;
}

sub add_1 {
    my $sum = 1;
    $sum += $_ foreach @_;
    return $sum;
};

foreach my $expectations (
    { expected => 1,     call_this => 'one' },
    { expected => 0,     call_this => 'zero' },
    { expected => 1,     call_this => 'add_1', with_args => [ 0 ] },
    { expected => 2,     call_this => 'add_1', with_args => [ 1 ] },
    { expected => 6,     call_this => 'add_1', with_args => [ 2, 3 ] },

    # Error cases:
    { expected => undef, call_this => undef }, 
    { expected => undef, call_this => 'no_such_sub' }, 
    { expected => undef, call_this => 'not even possible' }, 
) {
    my $expected = $expectations->{expected};
    my $call_this = $expectations->{call_this};
    my @args =
        exists $expectations->{with_args}
            ? @{$expectations->{with_args}}
            : undef;

    my $actual;
    {
        local $^W = 0; # Because we feed this bad input on purpose.
        $actual = $fm->do_external_routine($call_this, @args);
    }

    my $arg_string;
    if (!defined $args[0]) {
        $arg_string = 'undef';
    } else {
        $arg_string = "'" . join("', '", @args) .  "'";
    }
    my $description = "do_external_routine($arg_string)";

    is($actual, $expected, $description);
}


}

