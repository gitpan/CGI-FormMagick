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
#line 66 lib/CGI/FormMagick/Validator.pm
BEGIN: {
    use CGI::FormMagick;
    use CGI::FormMagick::Validator;
    use vars qw($fm);
}
is( nonblank("abc"), "OK" , "Strings aren't blank" );
isnt( nonblank(""), "OK" , "Empty string is blank");
isnt( nonblank("  "), "OK" , "Spaces are blank");

}

{
#line 95 lib/CGI/FormMagick/Validator.pm
is( integer(5), "OK" , "5 is a positive integer");
isnt( integer(-5), "OK" , "-5 is not a positive integer");
isnt( integer(5.5), "OK" , "5.5 is not a positive integer");
isnt( integer(), "OK" , "undef is not a positive integer");
isnt( integer("abc"), "OK" , "Alpha chars are not a positive integer");
isnt( integer("2abc"), "OK" , "Alpha chars are not a positive integer");
isnt( integer("2abc"), "OK" , "Mixed alphanumeric is not a positive integer");
isnt( integer(0), "OK" , "0 is not a positive integer");

}

{
#line 123 lib/CGI/FormMagick/Validator.pm
is( number(2), "OK" , "Integers are numbers");
is( number(2.2), "OK" , "Real numbers are numbers");
is( number(".2"), "OK" , "Decimal numbers with no integer part are numbers");
isnt( number(), "OK" , "Undef is not a number");
isnt( number("abc"), "OK" , "Alpha chars are not numbers");
isnt( number("2abc"), "OK" , "Mixed alphanumeric is not a number");
is( number(-2), "OK" , "Negative integers are numbers");
is( number(-2.2), "OK" , "Negative real numbers are numbers");
is( number(5.3e10), "OK" , "Scientific notation is a number");
is( number(0), "OK" , "Zero is a number");

}

{
#line 153 lib/CGI/FormMagick/Validator.pm
is( word("abc"), "OK" , "Alpha string is a word");
is( word("123abc"), "OK" , "Alphanumeric string is a word");
isnt( word(""), "OK" , "Empty string is not a word");
isnt( word("abc def"), "OK" , "String with spaces is not a word");
isnt( word("abc&fed"), "OK" , "String with punctuation is not a word");

}

{
#line 178 lib/CGI/FormMagick/Validator.pm
is( minlength("abc", 2), "OK" , "3 letter string is at least 2 chars long");
isnt( minlength("abc", -2), "OK" , "Negative minlength should fail");
isnt( minlength("abc", 0), "OK" , "Zero minlength should fail");
isnt( minlength("abc", "def"), "OK" , "Non-numeric minlength should fail");
isnt( minlength("", 1), "OK" , "Too short string should fail");

}

{
#line 207 lib/CGI/FormMagick/Validator.pm
is( maxlength("abc", 5), "OK" , "3 letter string is less than 5 chars long");
isnt( maxlength("abc", -2), "OK" , "Negative maxlength should fail");
isnt( maxlength("abc", 0), "OK" , "Zero maxlength should fail");
isnt( maxlength("abc", "def"), "OK" , "Non-numeric maxlength should fail");
is( maxlength("", 1), "OK" , "Zero length string is less than 1 char long");

}

{
#line 235 lib/CGI/FormMagick/Validator.pm
is( exactlength("abc", 3), "OK" , "3 letter string is 3 chars long");
isnt( exactlength("abc", 5), "OK" , "3 letter string isn't 5 chars long");
isnt( exactlength("abc", -2), "OK" , "Negative length should fail");
is( exactlength("", 0), "OK" , "Empty string is zero length");
isnt( exactlength("abc", "def"), "OK" , "Non-numeric exactlength should fail");
isnt( exactlength("abc"), "OK", "undef exactlength should fail");

}

{
#line 266 lib/CGI/FormMagick/Validator.pm
ok( CGI::FormMagick::Validator->can('lengthrange'), "Lengthrange routine exists");
is( lengthrange("abc", 2,4), "OK" , "3 letter string is between 2 and 4 chars long");
is( lengthrange("abc", 3,3), "OK" , "3 letter string is between 3 and 3 chars long");
isnt( lengthrange("abc", 1,2), "OK" , "3 letter string is not between 1 and 2 chars long");
is( lengthrange("", 0,1), "OK" , "Empty string is zero length");
isnt( lengthrange("abc", -2,4), "OK" , "Negative length should fail");
isnt( lengthrange("abc", 5,3), "OK" , "Max length is less than min length");

}

{
#line 298 lib/CGI/FormMagick/Validator.pm
isnt( url('http://'), "OK" , "http:// is not a complete URL");
isnt( url('ftp://'), "OK" , "ftp:// is not a complete URL");
isnt( url('abc'), "OK" , "abc is not a valid URL");
isnt( url(), "OK" , "undef is not a valid URL");
isnt( url(''), "OK" , "empty string is not a valid URL");
is( url('http://a.bc'), "OK" , "http://a.bc is a valid URL");
is( url('ftp://a.bc:21/'), "OK" , "ftp://a.bc:21 is a valid URL");

}

{
#line 327 lib/CGI/FormMagick/Validator.pm
is( email('a@b.c'), "OK" , 'a@b.c is a valid email address');
is( email('a+b@c.d'), "OK" , 'a+b@c.d is a valid email address');
is( email('a-b=c@d.e'), "OK" , 'a-b=c@d.e is a valid email address');
isnt( email('abc'), "OK" , 'abc is not a valid email address');
isnt( email('a@b'), "OK" , 'a@b is not a valid email address');
isnt( email('@b.c'), "OK" , '@b.c is not a valid email address');
isnt( email(), "OK" , 'undef is not a valid email address');
isnt( email(""), "OK" , 'empty string is not a valid email address');

}

{
#line 356 lib/CGI/FormMagick/Validator.pm
is( domain_name("abc.com"), "OK" , "abc.com is a valid domain name");
isnt( domain_name("abc"), "OK" , "abc is not a valid domain name");
isnt( domain_name(), "OK" , "undef is not a valid domain name");
isnt( domain_name(""), "OK" , "empty string is not a valid domain name");

}

{
#line 380 lib/CGI/FormMagick/Validator.pm

SKIP: {
    skip "Net::IPV4Addr not installed", 7 unless eval {require Net::IPV4Addr};

    is( ip_number("1.2.3.4"), "OK" , "1.2.3.4 is a valid ip address");
    isnt( ip_number("1000.2.3.4"), "OK" , "1000.2.3.4 is not a valid ip address");
    isnt( ip_number("a.b.c.d"), "OK" , "a.b.c.d is not a valid ip address");
    isnt( ip_number("1.2.3"), "OK" , "1.2.3 is not a valid ip address");
    isnt( ip_number(), "OK" , "undef is not a valid ip address");
    isnt( ip_number(""), "OK" , "empty string is not a valid ip address");
    isnt( ip_number("abc"), "OK" , "abc is not a valid ip address");
}


}

{
#line 416 lib/CGI/FormMagick/Validator.pm
is( username("abc"), "OK" , "abc is a valid username");
isnt( username("123"), "OK" , "123 is not a valid username");
isnt( username(), "OK" , "undef is not a valid username");
isnt( username(""), "OK" , "empty string is not a valid username");
isnt( username("  "), "OK" , "spaces is not a valid username");

}

{
#line 441 lib/CGI/FormMagick/Validator.pm
isnt( password("abc"), "OK" , "abc is not a good password");
isnt( password(), "OK" , "undef is not a good password");
isnt( password(""), "OK" , "empty string is not a good password");
is( password("ab1C23FouR!"), "OK" , "ab1C23FouR! is a good password");

}

{
#line 467 lib/CGI/FormMagick/Validator.pm
isnt( date(), "OK" , "undef is not a date");
isnt( date(""), "OK" , "empty string is not a date");
isnt( date("abc"), "OK" , "abc is not a date");

}

{
#line 492 lib/CGI/FormMagick/Validator.pm

SKIP: {
    skip "Locale::Country not installed", 4 
        unless eval { require Locale::Country };

    ok( iso_country_code()      ne "OK" , "undef is not a country");
    ok( iso_country_code("")    ne "OK" , "empty string is not a country");
    ok( iso_country_code("00")  ne "OK" , "00 is not a country");
    ok( iso_country_code("au")  eq "OK" , "au is a country");
}


}

{
#line 531 lib/CGI/FormMagick/Validator.pm

SKIP: {
    skip "Geography::States broken, install v1.6 - this means you Skud", 5 
        unless 0;
        #unless eval { require Geography::States };

    ok( US_state("or")          eq "OK" , "Oregon is a US state");
    ok( US_state("OR")          eq "OK" , "Oregon is a US state");
    ok( US_state()              ne "OK" , "undef is not a US state");
    ok( US_state("")            ne "OK" , "empty string is not a US state");
    ok( US_state("zz")          ne "OK" , "zz is not a US state");

}


}

{
#line 567 lib/CGI/FormMagick/Validator.pm
ok( US_zipcode()            ne "OK" , "undef is not a US zipcode");
ok( US_zipcode("")          ne "OK" , "empty string is not a US zipcode");
ok( US_zipcode("abc")       ne "OK" , "abc is not a US zipcode");
ok( US_zipcode("2210")      ne "OK" , "2210 is not a US zipcode");
ok( US_zipcode("90210")     eq "OK" , "90210 is a US zipcode");
ok( US_zipcode("a0210")     ne "OK" , "a0210 is not a US zipcode");
ok( US_zipcode("123456789") eq "OK" , "123456789 is a valid US zipcode");
ok( US_zipcode("12345-6789") eq "OK" , "12345-6789 is a valid US zipcode");

}

{
#line 599 lib/CGI/FormMagick/Validator.pm
ok( credit_card_number()    ne "OK" , "undef is not a credit card number");
ok( credit_card_number("")  ne "OK" , "empty string is not a credit card number");
ok( credit_card_number("a") ne "OK" , "a is not a credit card number");
ok( credit_card_number("12")ne "OK" , "12 is not a credit card number");
ok( credit_card_number("4111 1111 1111 1111")
                            eq "OK" , "4111 1111 1111 1111 is a credit card number");
ok( credit_card_number("4111111111111111")
                            eq "OK" , "4111111111111111 is a credit card number");
ok( credit_card_number("4111111111111112")
                            ne "OK" , "4111111111111112 is not a credit card number");
ok( credit_card_number("411111111111111")
                            ne "OK" , "411111111111111 is not a credit card number");

}

{
#line 648 lib/CGI/FormMagick/Validator.pm

my ($m, $y) = (localtime)[4,5];
$m++;
$y += 1900;

TODO: {
    local $TODO = "WRITE THESE TESTS";
    ok(0);
}


}

{
#line 816 lib/CGI/FormMagick/Validator.pm
TODO: {
    local $TODO = "Make validate_field accept a fieldname instead of a fieldref";
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
    use CGI;
    $fm->{cgi} = CGI->new("");
    is($fm->validate_field("firstname"), "OK", "validate_field accepts field names");
}


}

