#!/usr/bin/perl -w 
#
# FormMagick (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# This software is distributed under the same licenses as Perl; see
# the file COPYING for details.

#
# $Id: Setup.pm,v 1.1 2001/09/24 20:10:47 skud Exp $
#

package    CGI::FormMagick;

use strict;
use Carp;
use File::Basename;

=pod 

=head1 NAME

CGI::FormMagick::Setup - setup/initialisation routines for FormMagick

=head1 SYNOPSIS

  use CGI::FormMagick;

=head1 DESCRIPTION

=head2 default_xml_filename()

default source filename to the same as the perl script, with .xml 
extension

=begin testing

BEGIN: {
    use vars qw( $fm );
    use lib "./lib";
    use CGI::FormMagick;
}

my $xml = qq(
  <FORM TITLE="FormMagick demo application" POST-EVENT="submit_order">
    <PAGE NAME="Personal" TITLE="Personal details" POST-EVENT="lookup_group_info">
      <FIELD ID="firstname" LABEL="first name" TYPE="TEXT" VALIDATION="nonblank"/>
      <FIELD ID="lastname" LABEL="last name" TYPE="TEXT" VALIDATION="nonblank"/>
    </PAGE>
  </FORM>
);

ok($fm = CGI::FormMagick->new(TYPE => 'STRING', SOURCE => $xml), "create fm object");

=end testing

=cut

sub default_xml_filename {
    
      my($scriptname, $scriptdir, $extension) =
         File::Basename::fileparse($0, '\.[^\.]+');
    
      return $scriptname . '.xml';
}


=pod

=head2 parse_xml()

Parses the source XML and returns the results as a Perl data structure.

=for testing
TODO: {
    local $TODO = "writeme";
    fail();
}

=cut

sub parse_xml {
    my ($self) = @_;

    my $p = new XML::Parser (Style => 'Tree');

    my $xml;

    if ($self->{inputtype} eq "FILE") {
        $xml = $p->parsefile($self->{source} || default_xml_filename());
    } elsif ($self->{inputtype} eq "STRING") {
        $xml = $p->parse($self->{source});
    } else {
        croak 'Invalid source type specified (should be "FILE" or "STRING")';
    }
    return $xml;
}

=head2 clean_xml()

Cleans up the output of parse_xml() and returns it as a nicer, more
usable data structure, like this:

    {
        'FORM' => {
            'POST-EVENT' => 'submit_order',
            'TITLE' => 'FormMagick demo application'
        },
        'PAGES' => [
            {
                 'POST-EVENT' => 'lookup_group_info',
                 'FIELDS' => [
                     {
                         'TYPE' => 'TEXT',
                         'ID' => 'firstname',
                         'VALIDATION' => 'nonblank',
                         'LABEL' => 'first name'
                     },
                     {
                         'TYPE' => 'TEXT',
                         'ID' => 'lastname',
                         'VALIDATION' => 'nonblank',
                         'LABEL' => 'last name'
                     }
                 ],
                 'NAME' => 'Personal',
                 'TITLE' => 'Personal details'
            }
        ]
    };

=for testing
is(ref($fm->{clean_xml}), "HASH", "clean_xml gives us a hash");
is($fm->{clean_xml}->{TITLE}, "FormMagick demo application", "Picked up form title");
is(ref($fm->{clean_xml}->{PAGES}), "ARRAY", "clean_xml gives us an array of pages");
is(ref($fm->{clean_xml}->{PAGES}->[0]), "HASH", "each page is a hashref");
is($fm->{clean_xml}->{PAGES}->[0]->{NAME}, "Personal", "Picked up first page's name");
is(ref($fm->{clean_xml}->{PAGES}->[0]->{FIELDS}), "ARRAY", "Page's fields are an array");

=cut

sub clean_xml {
    my $self = shift;
    my @pages;

    my $dirty_form = $self->{xml}->[1];

    for (my $i = 4; $i < scalar(@$dirty_form); $i += 4) { 
        my $page = $dirty_form->[$i][0];
        my @fields;
        for (my $j = 4; $j < scalar(@{$dirty_form->[$i]}); $j += 4) { 
            my $field = $dirty_form->[$i]->[$j]->[0];
            push @fields, $field;
        }
        $page->{FIELDS} = \@fields;
        push @pages, $page;
    }

    my $clean = {
        %{$dirty_form->[0]},
        PAGES => \@pages,
    };

    return $clean;
}

=pod

=head2 initialise_sessiondir($self)

Figures out where the session tokens should be kept.

=for testing
ok( CGI::FormMagick::initialise_sessiondir("abc"), "Initialise sessiondir with name");
ok( CGI::FormMagick::initialise_sessiondir(),      "Initialise sessiondir with undef");

=cut

sub initialise_sessiondir {
  my ($sessiondir) = @_;
  # use the user-defined session handling directory (or default to
  # session-tokens) to store session tokens
  if ($sessiondir) {
      return $sessiondir;
  } else {
    require File::Basename;

    my($scriptname, $scriptdir, $extension) =
      File::Basename::fileparse($0, '\.[^\.]+');

    return "$scriptdir/session-tokens";
  }
}

return "FALSE";     # true value ;)

=pod

=head1 SEE ALSO

CGI::FormMagick

=cut
