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
#line 31 lib/CGI/FormMagick/HTML.pm
BEGIN: {
        use strict;
        use_ok('CGI::FormMagick');
        use vars qw($fm);
        use lib "lib/";
}

$fm = new CGI::FormMagick(TYPE => 'FILE', SOURCE => "t/simple.xml");
$fm->{cgi} = new CGI("");
isa_ok($fm, 'CGI::FormMagick');

our $minimalist_fieldinfo_ref = {
    VALIDATION => 'foo',
    LABEL => 'bar',
    TYPE => 'TEXT',
    ID => 'baz'
};


}

{
#line 269 lib/CGI/FormMagick/HTML.pm

sub plain_sub {
    return 'Vanilla';
}

sub add_1 {
    return $_[0] + 1;
}

sub add_together {
    my $sum = 0;
    $sum += $_ foreach @_;
    return $sum;
}

{
    foreach my $expectations (
        [ '', '' ],
        [ 'plain', 'plain' ],
        [ 'plain_sub()', 'Vanilla' ],
        [ 'add_1(0)', '1' ],
        [ 'add_1(1)', '2' ],
        [ 'add_together(2, 3)', '5' ],
        [ 'add_together(2, 3, 4)', '9' ],
    ) {
        my ($input, $expected) = @$expectations;

        my %f = %$minimalist_fieldinfo_ref;
        $f{VALUE} = $input;

        my $i = $fm->gather_field_info(\%f);
        my $actual = $i->{value};
        is(
            $actual,
            $expected,
            "gather_field_info('$input')"
        );
    }
}


}

{
#line 351 lib/CGI/FormMagick/HTML.pm
my $i = $fm->gather_field_info($minimalist_fieldinfo_ref);
ok(my $if = $fm->build_inputfield($i, CGI::FormMagick::TagMaker->new()), "build input field");

}

