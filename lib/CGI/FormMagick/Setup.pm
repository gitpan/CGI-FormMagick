#!/usr/bin/perl -w 
#
# FormMagick (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# This software is distributed under the same licenses as Perl; see
# the file COPYING for details.

#
# $Id: Setup.pm,v 1.14 2002/01/29 20:47:27 skud Exp $
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

ok($fm = CGI::FormMagick->new(TYPE => 'FILE', SOURCE => "t/simple.xml"), "create fm object");

=end testing

=cut

sub default_xml_filename {
    
      my($scriptname, $scriptdir, $extension) =
         File::Basename::fileparse($0, '\.[^\.]+');
    
      return $scriptname . '.xml';
}

=head2 parse_xml()

Parses the XML input, setting $fm->{xml} to a usable hash of the form
elements, and $fm->{lexicon} to a hash of the l10n lexicon.

The $fm->{xml} hash has the following form:

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
                     {
                         'TYPE' => 'FRAGMENT',
                         'CONTENT' => 'This is a simple fragment'
                     }
                     {
                         'TYPE' => 'SUBROUTINE',
                         'SRC' => 'fragment_subroutine_name()'
                     }
                 ],
                 'NAME' => 'Personal',
                 'TITLE' => 'Personal details'
            }
        ]
    };

=for testing
is(ref($fm->{xml}), "HASH", "parse_xml gives us a hash");
is($fm->{xml}->{TITLE}, "FormMagick demo application", 
    "Picked up form title");
is(ref($fm->{xml}->{PAGES}), "ARRAY", 
    "parse_xml gives us an array of pages");
is(ref($fm->{xml}->{PAGES}->[0]), "HASH", 
    "each page is a hashref");
is($fm->{xml}->{PAGES}->[0]->{NAME}, "Personal", 
    "Picked up first page's name");
is($fm->{xml}->{PAGES}->[0]->{TITLE}, "Personal details", 
    "Picked up first page's title");
is(ref($fm->{xml}->{PAGES}->[0]->{FIELDS}), "ARRAY", 
    "Page's fields are an array");
is(ref($fm->{xml}->{PAGES}->[0]->{FIELDS}->[0]), "HASH", 
    "Field is a hashref");
is($fm->{xml}->{PAGES}->[0]->{FIELDS}->[0]->{LABEL}, "first name", 
    "Picked up field title");
is($fm->{xml}{PAGES}[0]{FIELDS}[0]{DESCRIPTION}, "description here", 
    "Picked up field description");

=cut

sub parse_xml {
    my $self = shift;

    my $p = new XML::Parser (Style => 'Tree');

    my $xml;

    if ($self->{inputtype} eq "FILE") {
        $xml = $p->parsefile($self->{source} || default_xml_filename());
    } elsif ($self->{inputtype} eq "STRING") {
        $xml = $p->parse($self->{source});
    } else {
        croak 'Invalid source type specified (should be "FILE" or "STRING")';
    }

    my @dirty_form = @{$xml->[1]};

    my %form_attributes = %{$dirty_form[0]};

    my @form_elements = $self->clean_xml_array(@dirty_form[1..$#dirty_form]);

    my ($pages, $lexicon) = 
        $self->clean_page_list(\@form_elements, \%form_attributes);

    $self->{xml} = {
        %form_attributes,
        PAGES => $pages,
    };

    $self->{lexicon} = $lexicon;

}

=head2 clean_field_list

Given a messy field list (as seen as @page_fields in parse_xml()),
removes extraneous data and returns a clean list.

=cut

sub clean_field_list {
    my $self = shift;
    my @page_fields = @_;
    my @fields;
    FIELD: foreach my $field (@page_fields) {
        my $field_type = $field->[0];
        my %field_attributes = %{$field->[1]};
        my @this_field = @$field;
        my @field_elements = @this_field[2..$#this_field];
        @field_elements = $self->clean_xml_array(@field_elements);

        FIELD_ELEMENT: foreach my $field_element (@field_elements) {
            if ($field_type eq 'HTML') {
                $field_attributes{TYPE} = 'HTML';
                $field_attributes{CONTENT} = $field->[3];
            } elsif ($field_type eq 'SUBROUTINE') {
                $field_attributes{TYPE} = 'SUBROUTINE';
            } elsif ($field_element->{type}) {
                $field_attributes{$field_element->{type}} = 
                    $field_element->{content}->[2];
            } else {
                next FIELD_ELEMENT;
            }
        }

        push @fields, \%field_attributes;
    }

    return @fields;
}


=head2 clean_page_list(\@form_elements, \%form_attributes)

Given a messy list of form elements (as seen as @form_elements in 
parse_xml()), removes extraneous data and returns: 1) a
clean list of pages in the form, and 2) a lexicon hash.

=cut

sub clean_page_list {
    my $self = $_[0];
    my @form_elements = @{$_[1]};
    my %form_attributes = %{$_[2]};
    my @form_pages;
    my @lexicons;
    FORM_ELEMENT: foreach my $form_element (@form_elements) {
        if (not $form_element->{type}) {
            next FORM_ELEMENT;
        } elsif ($form_element->{type} eq 'PAGE') {
            push @form_pages, $form_element->{content};
        } elsif ($form_element->{type} eq 'LEXICON') {
            push @lexicons, $form_element->{content};
        } elsif ($form_element->{type}) {
            $form_attributes{$form_element->{type}} = 
                $form_element->{content}->[2];
        }
    }

    my @pages;
    PAGE: foreach my $page (@form_pages) {
        my %page_attributes = %{$page->[0]};
        my @this_page = @$page;
        my @page_elements = @this_page[1..$#this_page];
        @page_elements = $self->clean_xml_array(@page_elements);

        my @page_fields;
        #use Data::Dumper;
        #print Dumper @page_elements;
        PAGE_ELEMENT: foreach my $page_element (@page_elements) {
            if (not $page_element->{type}) {
                next PAGE_ELEMENT;
            } elsif ($page_element->{type} eq 'FIELD') {
                push @page_fields, 
                        ["FIELD", @{$page_element->{content}}];
            } elsif ($page_element->{type} eq 'HTML') {
                push @page_fields, 
                        ["HTML", @{$page_element->{content}}];
            } elsif ($page_element->{type} eq 'SUBROUTINE') {
                push @page_fields, 
                        ["SUBROUTINE", @{$page_element->{content}}];
            } elsif ($page_element->{type}) {
                $page_attributes{$page_element->{type}} = 
                    $page_element->{content}->[2];
            }
        }

        my @fields = $self->clean_field_list(@page_fields);

        push @pages, { %page_attributes, FIELDS => \@fields };
    }

    my %lexicon = CGI::FormMagick::L10N->get_lexicon(@lexicons);

    return \@pages, \%lexicon;
}

=head2 clean_xml_array($xml)

Cleans up XML by removing superfluous stuff.  Given an array of XML,
returns a cleaner array.

=cut

sub clean_xml_array {
    my ($self, @array) = @_;
    my @clean_array;
    for (my $i=0; $i <= @array; $i+=4) {
        my ($type, $content) = @array[$i+2, $i+3];
        push @clean_array, { type => $type, content => $content };
    }
    return @clean_array;
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
        return get_or_create_default_sessiondir();
    }
}

sub get_or_create_default_sessiondir {
    # It's recommended that you use a more hidden directory than this.
    # However, this is the best default we can think of:
    my $scriptdir = (File::Basename::fileparse($0, '\.[^\.]+'))[1];
    my $sessionid_dir_name = $scriptdir . "session-tokens/";

    ensure_dir_is_writable($sessionid_dir_name)
        or warn "(Expect CGI::Persistent to complain)";

    return $sessionid_dir_name;
}

sub ensure_dir_is_writable {
    my ($dir_name) = @_;

    if (not -d $dir_name) {
        mkdir($dir_name) or do {
            warn "Can't create $dir_name";
            return 0;
        }
    }

    if (not -w $dir_name) {
        warn "Can't write to $dir_name";
        return 0;
    }

    return 1;
}

return "FALSE";     # true value ;)

=pod

=head1 SEE ALSO

CGI::FormMagick

=cut
