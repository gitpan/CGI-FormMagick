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
#line 37 lib/CGI/FormMagick/Utils.pm

BEGIN: {
    use vars qw( $fm );
    use lib "./lib";
    use CGI::FormMagick;
}

ok($fm = CGI::FormMagick->new(TYPE => 'FILE', SOURCE => "t/simple.xml"), "create fm object");


}

{
#line 63 lib/CGI/FormMagick/Utils.pm
is($fm->get_page_by_name('Personal'), 0, "get page by name");

}

{
#line 84 lib/CGI/FormMagick/Utils.pm
is(ref($fm->get_page_by_number(0)), 'HASH', "get page by number");

}

{
#line 110 lib/CGI/FormMagick/Utils.pm

local $fm->{page_stack} = "0,1,2,3";
my $p = $fm->pop_page_stack();
is($p, 3, "Pop page stack return value");
is($fm->{page_stack}, "0,1,2", "Pop page stack changes stack");

local $fm->{page_stack} = "0";
$p = $fm->pop_page_stack();
is($p, 0, "Pop page stack return value");
is($fm->{page_stack}, "", "Pop page stack changes stack");


}

{
#line 141 lib/CGI/FormMagick/Utils.pm

local $fm->{page_stack} = "0,1,2,3";
$fm->push_page_stack(4);
is($fm->{page_stack}, "0,1,2,3,4", "Push page stack changes stack");

local $fm->{page_stack} = "";
$fm->push_page_stack(0);
is($fm->{page_stack}, "0", "Push page stack changes empty stack");


}

{
#line 165 lib/CGI/FormMagick/Utils.pm
ok(defined($fm->parse_template), "Fail gracefully if no template");

}

{
#line 190 lib/CGI/FormMagick/Utils.pm
is(@{$fm->form->{PAGES}}, 3, "We have three pages");
local $fm->{page_number} = 1;
ok(! $fm->is_last_page(), "It's not the last page");
local $fm->{page_number} = 3;
ok($fm->is_last_page(), "It is the last page");
local $fm->{page_number} = 99;
ok($fm->is_last_page(), "It's past the last page, but we cope OK");

}

{
#line 217 lib/CGI/FormMagick/Utils.pm
is(@{$fm->form->{PAGES}}, 3, "We have three pages");
local $fm->{page_number} = 0;
ok($fm->is_first_page(), "Is page 0 the first page");
local $fm->{page_number} = 1;
ok(!$fm->is_first_page(), "Is page 1 the first page");

}

{
#line 241 lib/CGI/FormMagick/Utils.pm
local $fm->{page_number} = 0;
local $fm->{cgi} = CGI->new("");
ok($fm->just_starting(), "Just starting");
local $fm->{page_number} = 0;
local $fm->{cgi} = CGI->new({ page => 1 });
ok(!$fm->just_starting(), "Not just starting");
local $fm->{page_number} = 0;
local $fm->{cgi} = CGI->new({ page => 0 });
ok(!$fm->just_starting(), "Not just starting even if page is 0");

}

{
#line 273 lib/CGI/FormMagick/Utils.pm

use CGI;

$cgi = CGI->new( { Finish => 1 } );
local $fm->{cgi} = $cgi;
local $fm->{page_number} = 3;
ok($fm->finished(), "User is finished (clicked Finish on last page)");

$cgi = CGI->new("");
local $fm->{cgi} = $cgi;
local $fm->{page_number} = 3;
ok($fm->finished(), "User is finished (last page, pressed enter)");

$cgi = CGI->new("");
local $fm->{cgi} = $cgi;
local $fm->{page_number} = 1;
ok(!$fm->finished(), "User is NOT finished (not last page, pressed enter)");

$cgi = CGI->new({ Previous => 1 });
local $fm->{cgi} = $cgi;
local $fm->{page_number} = 2;
ok(!$fm->finished(), "User is NOT finished (last page, didn't press enter)");


}

{
#line 332 lib/CGI/FormMagick/Utils.pm

use CGI;

my $cgi = CGI->new("");
local $fm->{cgi} = $cgi;
ok($fm->user_pressed_enter(), "User pressed enter");

$cgi = CGI->new({ Next => "foo" });
local $fm->{cgi} = $cgi;
ok(!$fm->user_pressed_enter(), "User clicked a button");


}

{
#line 365 lib/CGI/FormMagick/Utils.pm
my $form = $fm->form();
is(ref $form, "HASH", "form data structure is a hash");

}

{
#line 382 lib/CGI/FormMagick/Utils.pm
local $fm->{page_number} = 0;
my $page = $fm->page();
is(ref $page, "HASH", "page data structure is a hash");

}

{
#line 403 lib/CGI/FormMagick/Utils.pm
local $fm->{page_number} = 0;
local $fm->page->{FIELDS}->[0]->{TYPE} = 'TEXT';
is($fm->get_page_enctype(), 'application/x-www-urlencoded', 
   'Detected standard enctype');
local $fm->page->{FIELDS}->[0]->{TYPE} = 'FILE';
is($fm->get_page_enctype(), 'multipart/form-data',
   'Detected multipart enctype');

}

{
#line 432 lib/CGI/FormMagick/Utils.pm

local $fm->{cgi} = CGI->new({
    Previous => 1,
    Next => 1,
    Finish => 1,
    wherenext => 1,
});

$fm->clear_navigation_params();
is($fm->{cgi}->param("Previous"), undef, "Clear Previous param");
is($fm->{cgi}->param("Next"), undef, "Clear Next param");
is($fm->{cgi}->param("Finish"), undef, "Clear Finish param");
is($fm->{cgi}->param("wherenext"), undef, "Clear wherenext param");


}

