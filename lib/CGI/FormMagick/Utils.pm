#!/usr/bin/perl -w 
#
# FormMagick (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# This software is distributed under the same licenses as Perl; see
# the file COPYING for details.

#
# $Id: Utils.pm,v 1.1 2001/09/24 20:20:55 skud Exp $
#

package    CGI::FormMagick;

use Text::Template;

use strict;
use Carp;

=pod 

=head1 NAME

CGI::FormMagick::Utils - utility routines for FormMagick

=head1 SYNOPSIS

  use CGI::FormMagick;

=head1 DESCRIPTION

=head2 debug($msg)

The debug method prints out a nicely formatted debug message.  It can 
be called from your script as C<$f->debug($msg)>

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

sub debug {
    my $self = shift;
    my $msg = shift;
    my ($sub, $line) = (caller(1))[3,2];
    print qq(<p class="debug">$sub $line: $msg</p>) if $self->{debug};
}

=head2 $fm->get_page_by_name($name)

get a page given the NAME attribute.  Returns the numeric index of
the page, suitable for $wherenext.

=for testing
is($fm->get_page_by_name('Personal'), 0, "get page by name");

=cut

sub get_page_by_name {
    my ($self, $name) = @_;

    for (my $i = 0; $i < scalar(@{$self->{clean_xml}->{PAGES}}); $i += 1) { 
        return $i if $self->{clean_xml}->{PAGES}->[$i]->{NAME} eq $name;
    }
    return undef;   # if you can't find that page   
}

=pod

=head2 $fm->get_page_by_number($page_index)

Given a page index, return a hashref containing the page's data.
This is just a convenience function.

=for testing
is(ref($fm->get_page_by_number(0)), 'HASH', "get page by number");

=cut

sub get_page_by_number {
    my ($self, $pagenum) = @_;
    return $self->{clean_xml}->{PAGES}->[$pagenum];
}

=pod

=head2 pop_page_stack($self)

pops the last page off the stack of pages a user's visited... used
when the user clicks "Previous"

removes the last element from the stack (modifying it in place in
$self->{page_stack}) and returns the element it removed.  eg: 

    # if the CGI "pagestack" parameter is "1,2,3,5"...
    my $page = $self->pop_page_stack();
    $self->{page_stack} will be 1,2,3
    $page will be 5

=cut

sub pop_page_stack {
    my $self = shift;
    my @pages = split(",", $self->{page_stack});
    my $lastpage = pop(@pages);
    $self->{page_stack} = join(",", @pages);
    return $lastpage;
}

=pod

=head2 push_page_stack($newpage)

push a new page onto the page stack that keeps track of where a user
has been.

=cut

sub push_page_stack {
    my ($self, $newpage) = @_;
    $self->{page_stack} = "$self->{page_stack},$newpage";
    $self->{page_stack} =~ s/^,//;
}


=head2 $fm->parse_template($filename)

parses a Text::Template file and returns the result

=for testing
ok(defined($fm->parse_template), "Fail gracefully if no template");

=cut

sub parse_template {
    my $self = shift;
    my $filename = shift || "";
    my $output = "";
    if (-e $filename) {
    	my $template = new Text::Template (
    		TYPE => 'FILE', 
    		SOURCE => $filename
    	);
    	$output = $template->fill_in();
    }
    return $output;
}

=pod

=head2 $fm->form()

Gets the form we're dealing with.  With no args, returns an hashref to 
the form data structure. 


=for testing
my $form = $fm->form();
is(ref $form, "HASH", "form data structure is a hash");

=cut

sub form {
    my ($fm) = @_;
    return $fm->{clean_xml};
}

=pod

=head2 $fm->page()

Gets the current page we're dealing with, as a hashref.

=for testing
my $page = $fm->page();
is(ref $page, "HASH", "page data structure is a hash");

=cut

sub page {
    my ($fm) = @_;
    return $fm->form->{PAGES}->[$fm->{page_number}]
}

return "FALSE";     # true value

=pod

=head1 SEE ALSO

CGI::FormMagick;

=cut
