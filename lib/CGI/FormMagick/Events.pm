#!/usr/bin/perl -w 
#
# FormMagick (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# This software is distributed under the same licenses as Perl; see
# the file COPYING for details.

#
# $Id: Events.pm,v 1.1 2001/09/24 20:10:47 skud Exp $
#

package    CGI::FormMagick;

use strict;
use Carp;

=pod 

=head1 NAME

CGI::FormMagick::Events -- pre/post form/page event handlers

=head1 SYNOPSIS

  use CGI::FormMagick;


=head1 DESCRIPTION

=head2 form_pre_event($self)

performs the PRE-EVENT (if any) for the form.  Usually used to do
setup for the application.

this is the routine where we call some routine that will
give us default data for the form, or otherwise
do things that need doing before the form is submitted.

=cut

sub form_pre_event {
    my ($self) = @_;

    # find out what the form pre_event action is. 
    my $pre_form_routine = $self->{clean_xml}->{'PRE-EVENT'} || return;

    if ($pre_form_routine) {
        my $cp = $self->{calling_package};

        my $voodoo = "\&$cp\:\:$pre_form_routine(\$self->{cgi})"; 

        # if the pre_form_routine is defined in the calling file, 
        # it'll run. Otherwise, we'll give some simple display of the
        # variables that were submitted.

        unless (eval $voodoo) {
            debug($self, "<p>There was no pre-form routine.</p>\n")
        }
    }
}

=pod

=head2 form_post_event($self)

performs validation and runs the POST-EVENT (if any) otherwise just
prints out the data that the user input

Note: we need to validate EVERY ONE of the form inputs to make
sure malicious attacks don't happen.   See also "SECURITY 
CONSIDERATIONS" in the perldoc for how to get around this :-/

=cut

sub form_post_event {
    my ($self) = @_;

    $self->debug("This is the form post event");
    
    $self->validate_all();

    $self->debug("finished validating for form post event");

    if ($self->errors()) {

        $self->debug("Looks like we've got some errors");
      #print "<h2>", localise("Validation errors"), "</h2>\n";
      #print "<p>", localise("These validation errors are probably evidence of an attempt to circumvent the data validation on this application.  Please start over again."), "</p>";
      $self->list_error_messages();
    } else {
      $self->debug("Validation successful.");

      # find out what the form post_event action is. 
      my $post_form_routine = $self->{clean_xml}->{'POST-EVENT'};

      unless ($self->do_external_routine($post_form_routine)) {
  
        print "<p>", localise("The following data was submitted"), "</p>\n";
  
        print "<ul>\n";
        my @params = $self->{cgi}->param;
        foreach my $param (@params) {
          my $value =  $self->{cgi}->param($param);
          print "<li>$param: $value\n";
        }
        print "</ul>\n";
      }
    }
}

=pod

=head2 page_pre_event($self)

=cut


sub page_pre_event {
    my ($self) = @_;
    $self->debug("This is the page pre-event.");
    if (my $pre_page_routine = $self->page->{'PRE-EVENT'}) {
      $self->debug("The pre-routine is $pre_page_routine");
      $self->do_external_routine($pre_page_routine);
    }
}

=pod

=head2 page_post_event($self)

=cut

sub page_post_event {
    my ($self) = @_;
    $self->debug("This is the page post-event.");
    if (my $post_page_routine = $self->page->{'POST-EVENT'}) {
      $self->debug("The post-routine is $post_page_routine");
      $self->do_external_routine($post_page_routine);
    }
}


return "FALSE";  # true value

=pod

=head1 SEE ALSO

CGI::FormMagick

=cut
