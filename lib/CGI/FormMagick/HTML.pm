#!/usr/bin/perl -w 
#
# FormMagick (c) 2000 Kirrily Robert <skud@infotrope.net>
# This software is distributed under the GNU General Public License; see
# the file COPYING for details.

#
# NOTE TO DEVELOPERS: Use "XXX" to mark bugs or areas that need work
# use something like this to find how many things need work:
# find . | grep -v CVS | xargs grep XXX | wc -l
#

#
# $Id: HTML.pm,v 1.15 2001/09/24 02:03:17 skud Exp $
#

package    CGI::FormMagick;

use strict;
use Carp;
use CGI::FormMagick::L10N;

=pod 

=head1 NAME

CGI::FormMagick::HTML - HTML output routines for FormMagick

=begin testing
BEGIN: {
        use_ok('CGI::FormMagick');
        use vars qw($fm $i);
        use lib "lib/";
}

my $xml = qq(
  <FORM TITLE="FormMagick demo application" POST-EVENT="submit_order">
  <PAGE NAME="Personal" TITLE="Personal details" POST-EVENT="lookup_group_info">
  <FIELD ID="firstname" LABEL="first name" TYPE="TEXT" VALIDATION="nonblank"/>
  </PAGE>
  </FORM>
);

$fm = new CGI::FormMagick(TYPE => 'STRING', SOURCE => $xml);

=end testing

=head1 DESCRIPTION

These are internal-use-only routines for displaying HTML output,
probably only of interest to developers of FormMagick.

=head1 DEVELOPER ROUTINES 

=head2 print_buttons($fm)

print the table row containing the form's buttons

=cut

sub print_buttons {
  my $fm = shift;
  print qq(<tr><td></td><td class="buttons">);
  print qq(<input type="hidden" name="wherenext" value="Previous">) 
  	unless $fm->{page_number} == 1 or $fm->{previousbutton} == 0;
  my $label = $fm->localise("Previous");
  print qq(<input type="submit" name="wherenextb" value="$label">) 
  	unless $fm->{page_number} == 1 or $fm->{previousbutton} == 0;

  # check whether it's the last page yet
  if (scalar(@{$fm->{xml}[1]} + 1)/4 == $fm->{page_number}+1) {
    $label = $fm->localise("Finish");
    print qq(<input type="hidden" name="wherenext" value="Finish">\n);
    print qq(<input type="submit" name="wherenextb" value="$label">\n);
  } else {
    $label = $fm->localise("Next");
    print qq(<input type="hidden" name="wherenext" value="Next">\n);
    print qq(<input type="submit" name="wherenextb" value="$label">\n);
  }
  $label = $fm->localise("Clear this form");
  print qq(<input type="reset" value="$label">) 
  	if $fm->{resetbutton};
  print qq(</tr>);
}

=pod

=head2 print_form_header($fm)

prints the header template and the form title (heading level 1)

=cut 

sub print_form_header {
  my $fm = shift;
  my $title = $fm->{xml}[1][0]->{TITLE};

  # print out the templated headers (based on what's specified in the
  # HTML) then an h1 containing the FORM element's TITLE attribute
   
  print $fm->parse_template($fm->{xml}[1][0]->{HEADER});
  print "<h1>", $fm->localise($title), "</h1>\n";
}

=pod

=head2 print_form_footer($fm)

prints the stuff that goes at the bottom of every page of the form

=cut

sub print_form_footer {
  my $fm = shift;

  my $url = $fm->{cgi}->url();
  
  # here's how we clear our state IDs
  print qq(<p><a href="$url">Start over again</a></p>) 
  	if $fm->{startoverlink};

  # this is for debugging purposes
  $fm->debug(qq(<a href="$url?checkl10n=1">Check L10N</a>));

  # print the footer template
  print $fm->parse_template($fm->{xml}[1][0]->{FOOTER});
}


=pod

=head2 print_page_header($fm)

prints the page title (heading level 2) and description

=cut

sub print_page_header {

  my $fm = shift;
  my $title       = $fm->page->{TITLE};
  my $description = $fm->page->{DESCRIPTION};

  # the level 2 heading is the PAGE element's TITLE heading
  print "<h2>", $fm->localise($title), "</h2>\n";

  if ($description) {
	  print '<p class="pagedescription">', $fm->localise($description), "</p>\n";
  }

  my $url = $fm->{cgi}->url();
  print qq(<form method="POST" action="$url">\n);

  print qq(<input type="hidden" name="page" value="$fm->{page_number}">\n);
  print qq(<input type="hidden" name="page_stack" value="$fm->{page_stack}">\n);
  print $fm->{cgi}->state_field(), "\n";	# hidden field with state ID

  print "<table>\n";
  
}

=pod

=head2 print_page_footer($fm)

prints the stuff that goes at the bottom of a page, mostly just the
form and table close tags and stuff.

=cut

sub print_page_footer {
  my $fm = shift;
  
  print $fm->{cgi}->state_field();
  print "</table>\n</form>\n";
}

=pod 

=head2  print_field_description($description)

prints the description of a field

=cut

sub print_field_description {
	my $fm = shift;
	my $d = shift;
	$d = $fm->localise($d);
	print qq(<tr><td class="fielddescription" colspan=2>$d</td></tr>);
}


=pod

=head2 print_field_error($error)

prints any errors related to a field

=cut

sub print_field_error {
    my ($fm, $e) = @_;
    $e = $fm->localise($e);
    print qq(<br><div class="error" colspan=2>$e</div>);
}

=pod

=head2 display_fields($fm)

displays the fields for a page by looping through them

=cut 

sub display_fields {
  my ($fm) = @_;

  my @definitions;

  foreach my $field ( @{$fm->page->{FIELDS}} ) {

    my $info = $fm->gather_field_info($field);
    $fm->print_field_description($info->{description}) if $info->{description};
    
    if (($info->{type} eq "SELECT") || ($info->{type} eq "RADIO")) {
      $fm->set_option_lv($info);
    }

    print qq(<tr><td class="label">) . $fm->localise($info->{label}) ;
    
    # display errors (if any) below the field label.
    my $error = $fm->{errors}->{$info->{label}};
    $fm->print_field_error($error) if $error;
		
    my $inputfield = $fm->build_inputfield($info);
    print  qq(</td> <td class="field">$inputfield</td></tr>);

  }
}

=pod

=head2 gather_field_info($field) 

Gathers various information about a field and returns it as a hashref.

=begin testing
my $f = {			# minimalist fieldinfo hashref
	VALIDATION => 'foo',
	LABEL => 'bar',
	TYPE => 'TEXT',
	ID => 'baz'
};

$fm->{cgi} = CGI::new->("");

ok(($i = $fm->gather_field_info($f)), "Gather field info");
ok(ref($i) eq 'HASH', "gather_field_info returning a hashref");

=end testing 

=cut

sub gather_field_info {
    my ($fm, $fieldinfo) = @_;

    my %f;
    foreach (qw( VALIDATION LABEL TYPE ID OPTIONS DESCRIPTION CHECKED
    	MULTIPLE SIZE)) {
	    $f{lc($_)} = $fieldinfo->{$_} if $fieldinfo->{$_};
    }

    # value defaults to what the user filled in, if they filled
    # something in on a previous visit to this field
    if ($fm->{cgi}->param($f{id})) {
      $f{value} = $fm->{cgi}->param($f{id});

    # are we calling a subroutine to find the value?
    } elsif ($fieldinfo->{VALUE} && $fieldinfo->{VALUE} =~ /()$/) {
      $f{value} = $fm->call_defaultvalue_routine($fieldinfo->{VALUE}); 

    # otherwise, use VALUE attribute or default to blank.
    } else {
      $f{value} = $fieldinfo->{VALUE} || "";
    }

    $fm->debug("Field name is $f{id}");
    return \%f;
} 

=pod

=head2 build_inputfield ($fm, $forminfo)

Builds HTML for individual form fields. $forminfo is a hashref
containing information about the field. 

=for testing
ok(my $if = $fm->build_inputfield($i, CGI::FormMagick::TagMaker->new()), "build input field");

=cut

sub build_inputfield {
  my ($fm, $info) = @_;
  
  my $inputfield;		# HTML for a form input
  my $tagmaker = new CGI::FormMagick::TagMaker->new();

  if ($info->{type} eq "SELECT") {

    # don't specify a size if a size wasn't given in the XML
    if ($info->{size} && $info->{size} ne "") { 
      $inputfield = $tagmaker->select_start( 
        type     => $info->{type}, 
        name     => $info->{id},
        multiple => $info->{multiple},
        size     => $info->{size} 
      )
    } else {
      $inputfield = $tagmaker->select_start( 
        type     => $info->{type}, 
        name     => $info->{id},
        multiple => $info->{multiple},
      )
    }	

    $inputfield = $inputfield . $tagmaker->option_group( 
      value => $info->{option_values}, 
      text  => $info->{option_labels},
    ) .  $tagmaker->select_end;

  } elsif ($info->{type} eq "RADIO") {
    $inputfield = $tagmaker->input_group(
    type  => $info->{type},
    name  => $info->{id},
    value => $info->{option_values},
    text  => $info->{option_labels} 
    );

  } elsif ($info->{type} eq "CHECKBOX") {
    $inputfield = $tagmaker->input(
      type    => $info->{type},
      name    => $info->{id},
      value   => $info->{value},
      checked => $info->{checked},
      text    => $info->{label}
    );

  } else {
    # map HTML::TagMaker's functions to the type of this field.
    my %translation_table = (
      TEXTAREA => 'textarea',
      CHECKBOX => 'input_field',
      TEXT     => 'input_field',
    );
    my $function_name = $translation_table{$info->{type}};
    # make sure no size gets specified if the size isn't given in the XML
    if ($info->{size} && $info->{size} ne "") {
      $inputfield = $tagmaker->$function_name(
        type  => $info->{type},
        name  => $info->{id},
        value => $info->{value},
        size  => $info->{size},
      );
    } else {
      $inputfield = $tagmaker->$function_name(
        type  => $info->{type},
        name  => $info->{id},
        value => $info->{value},
      );
    }
  }
  return $inputfield;
}

=pod

=head2 set_option_lv($fm, $info)

Given $info (a hashref with info about a field) figures out the option
values/labels for SELECT or RADIO fields and shoves them into
$info->{option values} and $info->{option_labels}

=cut

sub set_option_lv {
    my ($fm, $info) = @_;

    # if this is a grouped input (one with options), we'll need to
    # run the options function for it. 

    # DWIM whether the options are in a hash or an array.
    my $lv_hashref = $fm->get_option_labels_and_values($info);
    
    $info->{option_labels} = $lv_hashref->{labels};
    $info->{option_values} = $lv_hashref->{vals};

}

return 1;