#!/usr/bin/perl -w

#
# FormMagick (c) 2000 Kirrily Robert <skud@infotrope.net>
# This software is distributed under the GNU General Public License; see
# the file COPYING for details.
#
# $Id: Basic.pm,v 1.5 2001/10/26 17:23:47 ryanking Exp $
#

package    CGI::FormMagick::Validator;
use strict;

=pod

=head1 NAME

CGI::FormMagick::Validator::Basic - basic validation routines for FM

=head1 SYNOPSIS

use CGI::FormMagick;

=head1 DESCRIPTION

See CGI::FormMagick::Validator for a general description.

=head2 Validation routines provided:

=over 4

=item nonblank

The data is not an empty string : C<$data ne "">

=for testing
BEGIN: {
    use CGI::FormMagick::Validator;
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

=item date

The data looks like a date.  Requires the Time::ParseDate module to be
installed.

=for testing
is(date('01/01/2000'), 'OK', "date('01/01/2000') should be valid.");
is(date('01/01/00'), 'OK', "date('01/01/00') should be valid.");
is(date('1/01/00'), 'OK', "date('1/01/00') should be valid.");
is(date('1/1/00'), 'OK', "date('1/1/00') should be valid.");
is(date('12/12/00'), 'OK', "date('12/12/00') should be valid.");
is(date('12/00'), 'OK', "date('12/00') should be valid.");
is(date('12/30/00'), 'OK', "date('12/30/00') should be valid.");
is(date('30/12/00'), 'OK', "date('30/12/00') should be valid.");
isnt(date('/00'), 'OK', "date('/00') shouldn't be valid.");
isnt(date('undef'), 'OK', "date('undef') shouldn't be valid.");
isnt(date(''), 'OK', "date('') shouldn't be valid.");
isnt(date('abc'), 'OK', "date('abc') shouldn't be valid.");

=cut

sub date {
    my $date = $_[0];
    require Time::ParseDate;
    if ($date && Time::ParseDate::parsedate($date)) {
        return "OK";
    } else {
        return "The data entered could not be parsed as a date"
    }
}

return "FALSE";
