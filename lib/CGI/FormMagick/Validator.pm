#!/usr/bin/perl -w

#
# FormMagick (c) 2000 Kirrily Robert <skud@infotrope.net>
# This software is distributed under the GNU General Public License; see
# the file COPYING for details.
#
# $Id: Validator.pm,v 1.6 2001/03/13 20:21:37 skud Exp $
#

package    CGI::FormMagick::Validator;
require    Exporter;
@ISA     = qw(Exporter);
@EXPORT  = qw( nonblank number word url username maxlength minlength exactlength);

=pod
=head1 NAME

CGI::FormMagick::Validator - validate data from FormMagick forms

=head1 SYNOPSIS

use CGI::FormMagick::Validator;

=head1 DESCRIPTION

This module provides some common validation routines.  Validation
routines return the string "OK" if they succeed, or a descriptive
message if they fail.

=head2 Validation routines provided:

=over 4

=item nonblank

The data is not an empty string : C<$data ne "">

=cut 

sub nonblank {
	my $data = $_[0];
	if ($data ne "") {
		return "OK";
	} else {
		return "This field must not be left blank"; 
	}
}

=pod

=item number

The data is a number (strictly speaking, data is a positive number):
C<$data =~ /^[0-9.]+$/>

=cut

sub number {
	my $data = $_[0];
	if ($data =~ /^[0-9.]+$/) {
		return "OK";
	} else {
		return "This field must contain a positive number";
	}
}

=pod

=item word

The data looks like a single word: C<$data !~ /\W/>

=cut

sub word {
	my $data = $_[0];
	if ($data =~ /^\w/) {
		return "OK";
	} else {
		return "This field must look like a single word.";
	}

}

=pod

=item minlength(n)

The data is at least C<n> characters long: C<length($data) E<gt>= $n>

=cut

sub minlength {
	my $data = $_[0];
	my $minlength= $_[1];
	if ( length($data) >= $minlength ) {
		return "OK";
	} else {
		return "This field must be at least $minlength characters";
	}
}


=pod

=item maxlength(n)

The data is no more than  C<n> characters long: C<length($data) E<lt>= $n>

=cut

sub maxlength {
	my $data = $_[0];
	my $maxlength= $_[1];
	if ( length($data) <= $maxlength ) {
		return "OK";
	} else {
		return "This field must be no more than $maxlength characters";
	}
}

=pod

=item exactlength(n)

The data is exactly  C<n> characters long: C<length($data) E== $n>

=cut

sub exactlength {
	my $data = $_[0];
	my $exactlength= $_[1];
	if ( length($data) == $exactlength ) {
		return "OK";
	} else {
		return "This field must be exactly $exactlength characters";
	}
}


=pod

=item lengthrange(n,m)

The data is between  C<n> and c<m> characters long: C<length($data) E<gt>= $n>
and C<length($data) E<lt>= $m>.
=cut

sub lengthrange {
	my $data = $_[0];
	my $minlength= $_[1];
	my $maxlength= $_[2];
	print "min $minlength, max $maxlength";
	if ( ( length($data) >= $minlength ) and (length($data) <= $maxlength) ) {
	        return "OK";
	} else {
		return "This field must be between $minlength and $maxlength characters";
	}
}


=pod


=item url

The data looks like a (normalish) URL: C<$data =~ m!(http|ftp)://[\w/.-/)!>

=cut

sub url {
	my $data = $_[0];
	if ($data =~ m!(http|ftp)://[\w/.-/]!) {
		return "OK";
	} else {
		return "This field must contain a URL starting with http:// or ftp://";
	}
}

=pod

=item email 

The data looks more or less like an internet email address:
C<$data =~ /\@/> 

Note: not fully compliant with the entire gamut of RFC 822 addressing ;)

=cut

sub email {
	my $data = $_[0];
	if ($data =~ /\@/) {
		return "OK";
	} else {
		return "This field doesn't look like an email address - it should contain an at-sign (\@)";
	}
}

=pod

=item domain_name

The data looks like an internet domain name or hostname.

=cut

sub domain_name {
	my $data = shift;
	if ($data =~ /^([a-z\d\-]+\.)+[a-z]{1,3}$/o ) {
		return "OK";
	} else {
		return "This field doesn't look like a valid Internet domain name or hostname.";
	}
}

=pod

=item ip_number

The data looks like a valid IP number.

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

=cut

sub username {
	my $data = $_[0];

	if ($data =~ /[a-zA-Z]{3,8}/ ) {
		return "OK";
	} else {
		return "This field must look like a valid username (3 to 8 letters and numbers)";
	}
}

=pod

=item password

The data looks like a good password

=cut

sub password {
	$_ = $_[0];	# easier to match on $_
	if (/\d/ and /[A-Z]/ and /[a-z]/ and /\W/ and length($_) > 6) {
		return "OK";
	} else {
		return "Not a good password.  Should have a mixture of upper and lower case letters, numbers, and non-alphanumeric characters.";
	}
}

=pod

=item date

The data looks like a date.  Requires the Time::ParseDate module to be
installed.

=cut

sub date {
	my $data = $_[0];
	require Time::ParseDate;
	if (my $time = parsedate($data)) {
		return "OK";
	} else {
		return "The data entered could not be parsed as a date"
	}
}

=pod

=item iso_country_code

The data is a standard 2-letter ISO country code.  Requires the Locale::Country 
module to be installed.

=cut

sub iso_country_code {
	my $data = $_[0];

	require Locale::Country;
	my @countries =  all_country_codes();

	foreach $country (@countries) {
	    if ($data eq $country) {
		return "OK";
	    }
	}
	return "This field does not contain an ISO country code";
}

=pod

=item US_state

The data is a standard 2-letter US state abbreviation.  Uses
Geography::State in non-strict mode, so this module must be installed
for it to work.

=cut

sub US_state {
	my $data = $_[0];
	require Geography::States;

	my $us = Geography::States->new('USA');

	if ($us->state(uc($data))) {
		return "OK";
	} else {
		return "This doesn't appear to be a valid 2-letter US state abbreviation"
	}			
}

=pod

=item US_zipcode

The data looks like a valid US zipcode

=cut

sub US_zipcode {
	my $data = $_[0];

	# pedantic point: US ZIP codes must contain 5 numbers, can
	# contain 9 (like "30308-1112"). Someone want to fix this?
 
	if ($data =~ /^\d{5}$/) {
		return "OK";
	    } else {
		return "US zip codes must contain 5 numbers";
	}
}

=pod

=item credit_card_number

The data looks like a valid credit card number.  Checks the input
for numeric characters only, length, and runs it through the checksumming 
algorithm used by most (all?) credit cards.

=cut

sub credit_card_number {
    my $data = $_[0];
    my ($i, $sum, $weight);
    
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

=head1 SEE ALSO

Be sure to read the SECURITY CONSIDERATIONS section in the main
CGI::FormMagick documentation for information on performing extra
validation under certain circumstances.

=head1 AUTHOR

Kirrily "Skud" Robert <skud@infotrope.net>

More information about FormMagick may be found at 
http://sourceforge.net/projects/formmagick/

=cut

return 1;
