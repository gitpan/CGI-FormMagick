#!/usr/bin/perl -w

#
# FormMagick (c) 2000 Kirrily Robert <skud@infotrope.net>
# This software is distributed under the GNU General Public License; see
# the file COPYING for details.
#
# $Id: Validator.pm,v 1.17 2001/09/24 02:03:17 skud Exp $
#

package    CGI::FormMagick::Validator;
require    Exporter;
@ISA = qw( Exporter );
@EXPORT  = qw( 
    do_validation_routine
    validate_field 
    validate_page 
    validate_all 
    list_error_messages
    errors
    nonblank
    integer 
    number 
    word 
    url 
    username 
    password
    domain_name 
    email
    date 
    maxlength 
    minlength
    exactlength 
    lengthrange
    US_state 
    US_zipcode 
    iso_country_code
    credit_card_number 
);

=pod

=head1 NAME

CGI::FormMagick::Validator - validate data from FormMagick forms

=head1 SYNOPSIS

use CGI::FormMagick;

=head1 DESCRIPTION

This module provides some common validation routines.  Validation
routines return the string "OK" if they succeed, or a descriptive
message if they fail.

=head2 Validation routines provided:

=over 4

=item nonblank

The data is not an empty string : C<$data ne "">

=for testing
BEGIN: {
    use CGI::FormMagick;
    use CGI::FormMagick::Validator;
    use vars qw($fm);
}
is( nonblank("abc"), "OK" , "Strings aren't blank" );
isnt( nonblank(""), "OK" , "Empty string is blank");
isnt( nonblank("  "), "OK" , "Spaces are blank");

=cut 

sub nonblank {
	my $data = $_[0];
        if (not $data) {
		return "This field must not be left blank"; 
	} elsif ( $data =~ /^\s+$/ ) {
		return "This field must not be left blank"; 
	} else {
		return "OK";
	}
}

=pod

=item integer

The data is a positive integer.

=for testing
is( integer(5), "OK" , "5 is a positive integer");
isnt( integer(-5), "OK" , "-5 is not a positive integer");
isnt( integer(5.5), "OK" , "5.5 is not a positive integer");
isnt( integer(), "OK" , "undef is not a positive integer");
isnt( integer("abc"), "OK" , "Alpha chars are not a positive integer");
isnt( integer("2abc"), "OK" , "Alpha chars are not a positive integer");
isnt( integer("2abc"), "OK" , "Mixed alphanumeric is not a positive integer");
isnt( integer(0), "OK" , "0 is not a positive integer");

=cut

sub integer {
	$_ = shift or return "This field must contain a positive integer";
	if (/^[0-9]+$/) {
		return "OK";
	} else {
		return "This field must contain a positive integer";
	}	
}

=pod

=item number

The data is a number (positive and negative real numbers, and scientific
notation are OK).

=for testing
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

=cut

sub number {
	my $data = shift ;
	defined($data) or return "This field must contain a number";
	if ($data =~ /^-?[0-9.]+$/) {
		return "OK";
	} else {
		return "This field must contain a number";
	}
}

=pod

=item word

The data looks like a single word: C<$data !~ /\W/>

=for testing
is( word("abc"), "OK" , "Alpha string is a word");
is( word("123abc"), "OK" , "Alphanumeric string is a word");
isnt( word(""), "OK" , "Empty string is not a word");
isnt( word("abc def"), "OK" , "String with spaces is not a word");
isnt( word("abc&fed"), "OK" , "String with punctuation is not a word");

=cut

sub word {
	my $data = $_[0];
	if ($data =~ /^\w+$/) {
		return "OK";
	} else {
		return "This field must look like a single word.";
	}

}

=pod

=item minlength(n)

The data is at least C<n> characters long: C<length($data) E<gt>= $n>

=for testing
is( minlength("abc", 2), "OK" , "3 letter string is at least 2 chars long");
isnt( minlength("abc", -2), "OK" , "Negative minlength should fail");
isnt( minlength("abc", 0), "OK" , "Zero minlength should fail");
isnt( minlength("abc", "def"), "OK" , "Non-numeric minlength should fail");
isnt( minlength("", 1), "OK" , "Too short string should fail");

=cut

sub minlength {
	my $data = shift; 
	my $minlength= shift;
	if (number($minlength) ne "OK" or $minlength <= 0) {
		return "Minimum length has been specified meaninglessly as $minlength"; 
	}
	if ( length($data) >= $minlength ) {
		return "OK";
	} else {
		return "This field must be at least $minlength characters";
	}
}


=pod

=item maxlength(n)

The data is no more than  C<n> characters long: C<length($data) E<lt>= $n>

=for testing
is( maxlength("abc", 5), "OK" , "3 letter string is less than 5 chars long");
isnt( maxlength("abc", -2), "OK" , "Negative maxlength should fail");
isnt( maxlength("abc", 0), "OK" , "Zero maxlength should fail");
isnt( maxlength("abc", "def"), "OK" , "Non-numeric maxlength should fail");
is( maxlength("", 1), "OK" , "Zero length string is less than 1 char long");

=cut

sub maxlength {
	my $data = $_[0];
	my $maxlength= $_[1];
	if (number($maxlength) ne "OK" or $maxlength <= 0) {
		return "Maximum length has been specified meaninglessly as $maxlength"; 
	}
	if ( length($data) <= $maxlength ) {
		return "OK";
	} else {
		return "This field must be no more than $maxlength characters";
	}
}

=pod

=item exactlength(n)

The data is exactly  C<n> characters long: C<length($data) E== $n>

=for testing
is( exactlength("abc", 3), "OK" , "3 letter string is 3 chars long");
isnt( exactlength("abc", 5), "OK" , "3 letter string isn't 5 chars long");
isnt( exactlength("abc", -2), "OK" , "Negative length should fail");
is( exactlength("", 0), "OK" , "Empty string is zero length");
isnt( exactlength("abc", "def"), "OK" , "Non-numeric exactlength should fail");
isnt( exactlength("abc"), "OK", "undef exactlength should fail");

=cut

sub exactlength {
    my ($data, $exactlength) = @_;
    if (not defined $exactlength) {
        return "You must specify the length for the field."; 
    } elsif ( $exactlength =~ /\D/ ) {
        return "You must specify the exactlength of the field with an integer";
    } elsif ( length($data) == $exactlength ) {
        return "OK";
    } else {
    	return "This field must be exactly $exactlength characters";
    }
}


=pod

=item lengthrange(n,m)

The data is between  C<n> and c<m> characters long: C<length($data) E<gt>= $n>
and C<length($data) E<lt>= $m>.

=for testing
ok( CGI::FormMagick::Validator->can('lengthrange'), "Lengthrange routine exists");
is( lengthrange("abc", 2,4), "OK" , "3 letter string is between 2 and 4 chars long");
is( lengthrange("abc", 3,3), "OK" , "3 letter string is between 3 and 3 chars long");
isnt( lengthrange("abc", 1,2), "OK" , "3 letter string is not between 1 and 2 chars long");
is( lengthrange("", 0,1), "OK" , "Empty string is zero length");
isnt( lengthrange("abc", -2,4), "OK" , "Negative length should fail");
isnt( lengthrange("abc", 5,3), "OK" , "Max length is less than min length");

=cut

sub lengthrange {
    my ($data, $minlength, $maxlength) = @_;
    if (not defined $minlength or not defined $maxlength) {
        return "You must specify the maximum and minimum length for the field."; 
    } elsif ( $maxlength =~ /\D/ or $minlength =~ /\D/ ) {
        return "You must specify the maximum and minimum lengths of the field with an integer";
    } elsif ( ( length($data) >= $minlength ) and (length($data) <= $maxlength) ) {
        return "OK";
    } else {
        return "This field must be between $minlength and $maxlength characters";
    }
}


=pod


=item url

The data looks like a (normalish) URL: C<$data =~ m!(http|ftp)://(\w/.-/+)!>

=for testing
isnt( url('http://'), "OK" , "http:// is not a complete URL");
isnt( url('ftp://'), "OK" , "ftp:// is not a complete URL");
isnt( url('abc'), "OK" , "abc is not a valid URL");
isnt( url(), "OK" , "undef is not a valid URL");
isnt( url(''), "OK" , "empty string is not a valid URL");
is( url('http://a.bc'), "OK" , "http://a.bc is a valid URL");
is( url('ftp://a.bc:21/'), "OK" , "ftp://a.bc:21 is a valid URL");

=cut

sub url {
	my $data = $_[0];
	if ($data && $data =~ m!(http|ftp)://[\w/.-/]!) {
		return "OK";
	} else {
		return "This field must contain a URL starting with http:// or ftp://";
	}
}

=pod

=item email 

The data looks more or less like an internet email address:
C<$data =~ /.+\@.+\..+/> 

Note: not fully compliant with the entire gamut of RFC 822 addressing ;)

=for testing
is( email('a@b.c'), "OK" , 'a@b.c is a valid email address');
is( email('a+b@c.d'), "OK" , 'a+b@c.d is a valid email address');
is( email('a-b=c@d.e'), "OK" , 'a-b=c@d.e is a valid email address');
isnt( email('abc'), "OK" , 'abc is not a valid email address');
isnt( email('a@b'), "OK" , 'a@b is not a valid email address');
isnt( email('@b.c'), "OK" , '@b.c is not a valid email address');
isnt( email(), "OK" , 'undef is not a valid email address');
isnt( email(""), "OK" , 'empty string is not a valid email address');

=cut

sub email {
    my $data = $_[0];
    if (not defined $data ) {
        return "You must enter an email address.";
    } elsif ($data =~ /.+\@.+\..+/) {
        return "OK";
    } else {
        return "This field doesn't look like an email address - it should contain an at-sign (\@)";
    }
}

=pod

=item domain_name

The data looks like an internet domain name or hostname.

=for testing
is( domain_name("abc.com"), "OK" , "abc.com is a valid domain name");
isnt( domain_name("abc"), "OK" , "abc is not a valid domain name");
isnt( domain_name(), "OK" , "undef is not a valid domain name");
isnt( domain_name(""), "OK" , "empty string is not a valid domain name");

=cut

sub domain_name {
	my $data = shift;
	if ($data && $data =~ /^([a-z\d\-]+\.)+[a-z]{1,3}\.?$/o ) {
		return "OK";
	} else {
		return "This field doesn't look like a valid Internet domain name or hostname.";
	}
}

=pod

=item ip_number

The data looks like a valid IP number.

=begin testing

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

=end testing

=cut

sub ip_number {
	my $data = $_[0];

	require Net::IPV4Addr;

	if (ipv4_chkip($data)) {
		return OK;
	} else {
		return "This field doesn't look like an IP number.";
	}

}

=pod

=item username

The data looks like a good, valid username

=for testing
is( username("abc"), "OK" , "abc is a valid username");
isnt( username("123"), "OK" , "123 is not a valid username");
isnt( username(), "OK" , "undef is not a valid username");
isnt( username(""), "OK" , "empty string is not a valid username");
isnt( username("  "), "OK" , "spaces is not a valid username");

=cut

sub username {
	my $data = $_[0];

	if ($data && $data =~ /[a-zA-Z]{3,8}/ ) {
		return "OK";
	} else {
		return "This field must look like a valid username (3 to 8 letters and numbers)";
	}
}

=pod

=item password

The data looks like a good password

=for testing
isnt( password("abc"), "OK" , "abc is not a good password");
isnt( password(), "OK" , "undef is not a good password");
isnt( password(""), "OK" , "empty string is not a good password");
is( password("ab1C23FouR!"), "OK" , "ab1C23FouR! is a good password");

=cut

sub password {
    $_ = shift;  # easier to match on $_
    if (not defined $_) {
        return "You must provide a password.";
    } elsif (/\d/ and /[A-Z]/ and /[a-z]/ and /\W/ and length($_) > 6) {
	return "OK";
    } else {
    	return "The password you provided was not a good password.  A good password should have a mixture of upper and lower case letters, numbers, and non-alphanumeric characters.";
    }
}

=pod

=item date

The data looks like a date.  Requires the Time::ParseDate module to be
installed.

=for testing
isnt( date(), "OK" , "undef is not a date");
isnt( date(""), "OK" , "empty string is not a date");
isnt( date("abc"), "OK" , "abc is not a date");

=cut

sub date {
	my $data = $_[0];
	require Time::ParseDate;
	if ($date && (my $time = Time::ParseDate::parsedate($data))) {
		return "OK";
	} else {
		return "The data entered could not be parsed as a date"
	}
}

=pod

=item iso_country_code

The data is a standard 2-letter ISO country code.  Requires the Locale::Country 
module to be installed.

=begin testing

SKIP: {
    skip "Locale::Country not installed", 4 
        unless eval { require Locale::Country };

    ok( iso_country_code()      ne "OK" , "undef is not a country");
    ok( iso_country_code("")    ne "OK" , "empty string is not a country");
    ok( iso_country_code("00")  ne "OK" , "00 is not a country");
    ok( iso_country_code("au")  eq "OK" , "au is a country");
}

=end testing

=cut

sub iso_country_code {
    my ($country) = @_;

    require Locale::Country;
    my @countries =  Locale::Country::all_country_codes();

    if ( not defined $country ) {
        return "You must provide a country code";
    } elsif ( grep /^$country$/, @countries ) {
        return "OK";
    } else {
        return "This field does not contain an ISO country code";
    }
}

=pod

=item US_state

The data is a standard 2-letter US state abbreviation.  Uses
Geography::State in non-strict mode, so this module must be installed
for it to work.

=begin testing

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

=end testing

=cut

sub US_state {
	my $data = $_[0];
	require Geography::States;

	my $us = Geography::States->new('USA');

	if ($data && $us->state(uc($data))) {
		return "OK";
	} else {
		return "This doesn't appear to be a valid 2-letter US state abbreviation"
	}			
}


=item US_zipcode

The data looks like a valid US zipcode

=for testing
ok( US_zipcode()            ne "OK" , "undef is not a US zipcode");
ok( US_zipcode("")          ne "OK" , "empty string is not a US zipcode");
ok( US_zipcode("abc")       ne "OK" , "abc is not a US zipcode");
ok( US_zipcode("2210")      ne "OK" , "2210 is not a US zipcode");
ok( US_zipcode("90210")     eq "OK" , "90210 is a US zipcode");
ok( US_zipcode("a0210")     ne "OK" , "a0210 is not a US zipcode");
ok( US_zipcode("123456789") eq "OK" , "123456789 is a valid US zipcode");
ok( US_zipcode("12345-6789") eq "OK" , "12345-6789 is a valid US zipcode");

=cut

sub US_zipcode {
    my $data = $_[0];

    if (not $data) {
        return "You must enter a US zip code";
    } elsif ($data =~ /^\d{5}(-?\d{4})?$/) {
    	return "OK";
    } else {
        return "US zip codes must contain 5 or 9 numbers";
    }
}

=pod

=item credit_card_number

The data looks like a valid credit card number.  Checks the input
for numeric characters only, length, and runs it through the checksumming 
algorithm used by most (all?) credit cards.

=for testing
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

=cut

sub credit_card_number {
    my $number = $_[0];
    my ($i, $sum, $weight);

    return "You must enter a credit card number" unless $number;

    return "Credit card numbers may only contain numeric characters" 
	if $number =~ /[^\d\s]/;

    $number =~ s/\D//g;

    return "Must be at least 14 characters in length" 
	unless length($number) >= 13 && 0+$number;

    for ($i = 0; $i < length($number) - 1; $i++) {
        $weight = substr($number, -1 * ($i + 2), 1) * (2 - ($i % 2));
        $sum += (($weight < 10) ? $weight : ($weight - 9));
    }

    return "OK" if substr($number, -1) == (10 - $sum % 10) % 10;
    return "Doesn't appear to be a valid credit card number";

}

=pod

=item credit_card_expiry

The data looks like a valid credit card expiry date.  Checks MM/YY and 
MM/YYYY format dates and fails if the date is in the past or is more than 
ten years in the future.

=begin testing

my ($m, $y) = (localtime)[4,5];
$m++;
$y += 1900;

TODO: {
    local $TODO = "WRITE THESE TESTS";
    ok(0);
}

=end testing

=cut

#
# this validation routine was snarfed whole from Business::CreditCard
#

sub credit_card_expiry {
	my $data = $_[0];
	my ($m, $y) = split(/\D/, $data); # split on first non-numeric char

	return "Expiry date must be in the format MM/YY or MM/YYYY"
		if ($y =~ /\D/ or $m =~ /\D/);

	my ($thism, $thisy) = (localtime())[4,5];
	$y += (substr($thisy, 0, 2) * 100) if $y =~ /\d{2}/;

	if ($y < $thisy) {
		return "This expiry date appears to have already passed";
	} elsif ($m < $thism) {
		return "This expiry date appears to have already passed";
	} elsif ($y > ($thisy + 10)) {
		return "This expiry date is too far in the future";
	} else {
		return "OK";
	}
}



=pod

=back

=head2 Using more than one validation routine per field

You can use multiple validation routines like this:

    VALUE="foo" VALIDATION="my_routine, my_other_routine"

However, there are some requirements on formatting to make sure that
FormMagick can parse what you've given it.

=over 4

=item *

Parens are optional on subroutines with no args.  C<my_routine> is
equivalent to C<my_routine()>.

=item *

You B<MUST> put a comma then a space between routine names, eg
C<my_routine, my_other_routine> B<NOT> C<my_routine,my_other_routine>.

=item *

You B<MUST NOT> put a comma between args to a routine, eg
C<my_routine(1,2,3)> B<NOT> C<my_routine(1, 2, 3)>.

=back

This will be fixed to be more flexible in a later release.

=head2 Making your own routines

FormMagick's validation routines may be overridden and others may be added on 
a per-application basis.  To do this, simply define a subroutine in your
CGI script that works in a similar way to the routines provided by
CGI::FormMagick::Validator and use its name in the VALIDATION attribute 
in your XML.

The arguments passed to the validation routine are the value of the
field (to be validated) and any subsequent arguments given in the
VALIDATION attribute.  For example:

    VALUE="foo" VALIDATION="my_routine"
    ===> my_routine(foo)

    VALUE="foo" VALIDATION="my_routine(42)"
    ===> my_routine(foo, 42)

The latter type of validation routine is useful for routines like
C<minlength()> and C<lengthrange()> which come with
CGI::FormMagick::Validator.

Here's an example routine that you might write:

    sub my_grep {
        my $data = shift;
        my @list = @_;
        if (grep /$data/, @list) {
            return "OK" 
        } else {
            return "That's not one of: @list"
        }
    }


=pod

=head1 SECURITY CONSIDERATIONS AND METHODS FOR MANUAL VALIDATION

If you use page POST-EVENT or PRE-EVENT routines which perform code
which is in any way based on user input, your application may be
susceptible to a security exploit.

The exploit can occur as follows:

Imagine you have an application with three pages.  Page 1 has fields A,
B and C.  Page 2 has fields D, E and F.  Page 3 has fields G, H and I.

The user fills in page 1 and the data FOR THAT PAGE is validated before 
they're allowed to move on to page 2.  When they fill in page 2, the
data FOR THAT PAGE is validated before they can move on.  Ditto for page
3.  

If the user saves a copy of page 2 and edits it to contain an extra
field, "A", with an invalid value, then submits that page back to
FormMagick, the added field "A" will NOT be validated.

This is because FormMagick relies on the XML description of the page to
know what fields to validate.  Only the current page's fields are
validated, until the very end when all the fields are revalidated one
last time before the FORM POST-EVENT is run.  This means that we don't
suffer the load of validating everything every time, and it will work
fine for most applications.

However, if you need to run PAGE POST-EVENT or PRE-EVENT routines that
rely on previous pages' data, you should validate it manually in your
POST-EVENT or PRE-EVENT routine.  The following methods are used
internally by FormMagick for its validation, but may also be useful to
developers.

Note: this stuff may be buggy.  Please let us know how you go with it.

=head2 $fm->validate_field($fieldname | $fieldref)

This routine allows you to validate a specific field by hand if you need
to.  It returns a string with the error message if validation fails, or
the string "OK" on success.

Examples of use:

This is how you'd probably call it from your script:

  if ($fm->validate_field("credit_card_number") eq "OK")) { }

FormMagick uses references to a field object, internally:

  if ($fm->validate_field($fieldref) eq "OK")) { }

(that's so that FormMagick can easily loop through the fields in a page;
you shouldn't need to do that)


=begin testing
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

=end testing

=cut


#----------------------------------------------------------------------------
# validate_field($self, $fieldname | $fieldref)
#
# validates end-user input for an individual field. 
#----------------------------------------------------------------------------

sub validate_field {
  my ($self, $fieldinfo) = @_; 
  #TODO: make this take fieldnames, not just fieldrefs.

  my $validation = $fieldinfo->{VALIDATION};
  my $fieldname  = $fieldinfo->{ID};
  my $fieldlabel = $fieldinfo->{LABEL} || "";
  my $fielddata  = $self->{cgi}->param($fieldname);

  $self->debug("Validating field $fieldname");

  # just skip everything else if there's no validation to do.
  return "OK" unless $validation;

  my @results;
  # XXX argh! this split statement requires that we write validators like 
  # "lengthrange(4, 10), word" like "lengthrange(4,10), word" in order to 
  # work. Eeek. That's not how this should work. But it was even
  # more broken before (I changed a * to a +). 
  # OTOH, I'm not sure it's fixed now. --srl

  my @validation_routines = split( /,\s+/, $validation);
  # $self->debug("Going to perform these validation routines: @validation_routines");

  foreach my $v (@validation_routines) {
    my ($validator, $arg) = parse_validation_routine($v);
    my $result = $self->do_validation_routine ($validator, $arg, $fielddata);

    push (@results, $result) if $result ne "OK";
	
    # for multiple errors, put semicolons between the errors before
    # shoving them in a hash to return.    

    if (@results)   {
      my $formatted_result = join("; ", @results) . "." ;
      return $formatted_result if ($formatted_result ne ".");
    } 

  }
  return "OK";
}

=pod

=head2 $fm->validate_page($number | $name)

This routine allows you to validate a single page worth of fields.  It
can accept either a page number (counting naturally from one, B<NOT> 
starting at zero), a page name, or a reference to a page object.  You'll
probably want to use the name or number; the page reference is used
internally by FormMagick's C<validate_all()> routine to loop through
all the pages in the form.

This routine returns a hash of errors, with the keys being the names of
fields which have errors and the values being the error messages.  You
can test for whether something's passed validation by testing for a true
return value.

Examples:
my %errors = $fm->validate_page(3);
  my %errors = $fm->validate_page("CreditCardDetails");
  if (%errors) { ... }

=cut

sub validate_page {

  my ($self, $param) = @_;
  my $page_index;	# what page number is this?
  my $page_ref;     

  # XXX should these next 15 lines or so be their own sub?
  # DWIM with $param; handle gracefully if we got a name, number or ref

  if (int($param) eq $param ) {
    $page_index = $param;
  } else {
    $page_index = $self->get_page_by_name($param) || 
        $self->debug("Arg to validate_page wasn't a valid number or name.");
  }

  $self->debug("Validating page $page_index.");

  my %errors;
 
  # walk through the fields on the given page
  foreach my $field (@{$self->{clean_xml}->{PAGES}->[$page_index]->{FIELDS}}) {
        #$self->debug("About to validate field $field->{ID}");
	my $result = $self->validate_field($field);
	unless ($result eq "OK") {
		$errors{$field->{LABEL}} = $result;
	}
  } 

  $howmany = (keys %errors);
  $self->debug("Done validating page $page_index.  Found $howmany errors.");
  
  $self->{errors} = \%errors;
  return %errors;
}

=pod

=head2 $fm->validate_all()

This routine goes through all the pages that have been visited (using
FormMagick's built-in page stack to keep track of which these are) and
runs C<validate_page()> on each of them.

Returns a hash of all errors, and set $self->{errors} when done.

=cut

sub validate_all {
	my ($self) = @_;

	my %errors;

	$self->debug("Validating all form input.");

	# Walk through all the pages on the stack and make sure
	# the data for their fields is still valid
	foreach my $pagenum ( (split(/,/, $self->{page_stack})), $self->{page_number} ) {
		# add the errors from this page to the errors from any other pages
		%errors = ( %errors, $self->validate_page($pagenum) );
	}

	$self->{errors} = \%errors;
        return %errors;
}


=pod

=head1 DEVELOPER METHODS

The following methods are probably not of interest to anyone except
developers of FormMagick


=head2 parse_validation_routine ($validation_routine_name)

parse the name of a validation routine into its name and its parameters.
returns a 2-element list, $validator and $arg.

=cut

sub parse_validation_routine {
	my ($validation_routine_name) = @_;
	
	my ($validator, $arg) = ($validation_routine_name =~ 
		m/
		^		# start of string
		(\w+)		# a word (--> $validator)
		(?:		# non-capturing (to group the (.*))
		\(		# literal paren
		(.*)		# whatever's inside the paren (--> $arg)
		\)		# literal close paren
		)?		# (.*) is optional (zero or one of them)
		$		# end of string
		/x );

	return ($validator, $arg);
}

=pod

=head2 do_validation_routine ($self, $validator, $arg, $fielddata)

runs validation functions with arguments. 

=cut

sub do_validation_routine {
  my ($self, $validator, $arg, $fielddata) = @_;
  $fielddata ||= "";
  my $result;

  my $cp = $self->{calling_package};

  # TODO: this could use some documentation.
  if ($arg) {
    #$self->debug("Args found: $arg");
    if ($result = (eval "&${cp}::$validator('$fielddata', $arg)")) {
      $self->debug("Called user validation routine $validator('$fielddata', $arg)");
    } elsif ($result = (eval "&CGI::FormMagick::Validator::" 
          . "$validator('$fielddata', $arg)")) {
      $self->debug("Called builtin validation routine $validator('$fielddata', $arg)");
    } else {
      $self->debug("Eval failed: $@");
    }
  } else { 
    #$self->debug("No args found");
    if ($result = (eval "&${cp}::$validator('$fielddata')")) {
      $self->debug("Called user validation routine");
    } elsif ($result = (eval "&CGI::FormMagick::Validator::" 
          . "$validator('$fielddata')")) {
      $self->debug("Called builtin validation routine $validator('$fielddata')");
    } else {
      $self->debug("Eval failed: $@");
    }
  }

  $self->debug("Validation result is $result");
  return $result;
}	

=pod

=head2 list_error_messages()

prints a list of error messages caused by validation failures

=cut

sub list_error_messages {
	print qq(<div class="error">\n);
	print qq(<h3>Errors</h3>\n);
	print "<ul>";

	foreach my $field (keys %{$self->{errors}}) {
		print "<li>$field: $self->{errors}->{$field}\n";
	}
	print "</ul></div>\n";
}


sub errors {
    my $self = shift;
    return %{$self->{errors}};
}


=pod

=head1 SEE ALSO

The main perldoc for CGI::FormMagick

=head1 AUTHOR

Kirrily "Skud" Robert <skud@infotrope.net>

More information about FormMagick may be found at 
http://sourceforge.net/projects/formmagick/

=cut

return 1;
