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
# $Id: HTML.pm,v 1.41 2002/02/04 22:53:25 skud Exp $
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

=end testing

=head1 DESCRIPTION

These are internal-use-only routines for displaying HTML output,
probably only of interest to developers of FormMagick.

=head1 DEVELOPER ROUTINES 

=head2 $self->print_page()

Prints out a page of the form, including the page header and footer, the 
fields, and the buttons.

=cut

sub print_page {
    my ($self) = @_;
    $self->print_page_header();
    $self->display_fields();
    $self->print_buttons();
    $self->print_page_footer();
}



=head2 print_buttons($fm)

print the table row containing the form's buttons

=cut

sub print_buttons {
    my $fm = shift;
    print "\n";
    print qq(<tr><td></td><td><div class="buttons">);
    my $label = $fm->localise("Previous");
    print qq(<input type="submit" name="Previous" value="$label">) 
  	unless $fm->{page_number} == FIRST_PAGENUM() 
        or $fm->{previousbutton} == 0;

    # check whether it's the last page yet
    if ($fm->is_last_page()) {
        $label = $fm->localise("Finish");
        print qq(<input type="submit" name="Finish" value="$label">\n);
    } else {
        if ($fm->{nextbutton}) {
            $label = $fm->localise("Next");
            print qq(<input type="submit" name="Next" value="$label">\n);
        }
    }
    $label = $fm->localise("Clear this form");
    print qq(<input type="reset" value="$label">) 
  	if $fm->{resetbutton};
    print qq(</div></td></tr>);
}


=pod

=head2 print_form_header($fm)

prints the header template and the form title (heading level 1)

=cut 

sub print_form_header {
    my $fm = shift;
    my $title = $fm->form->{TITLE};

    # print out the templated headers (based on what's specified in the
    # HTML) then an h1 containing the FORM element's TITLE attribute
   
    print $fm->parse_template($fm->form->{HEADER});
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
    $fm->debug_msg(qq(<a href="$url?checkl10n=1">Check L10N</a>));

    # print the footer template
    print $fm->parse_template($fm->form->{FOOTER});
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
    my $enctype = $fm->get_page_enctype();
    print qq(<form method="POST" action="$url" enctype="$enctype">\n);

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
    print qq(<tr><td><div class="fielddescription" colspan=2>$d</div></td></tr>);
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
        if ($info->{type} eq "HTML") {
            print qq(<tr><td cols="2">$info->{content}</td></tr>\n);
        } elsif ($info->{type} eq "SUBROUTINE") {
            my $output = $fm->call_subroutine_fragment($info->{src});
            print qq(<tr><td cols="2">$output</td></tr>\n);
        } else {
            $fm->print_field_description($info->{description}) 
                if $info->{description};
        
            if (($info->{type} eq "SELECT") || ($info->{type} eq "RADIO")) {
                $fm->set_option_lv($info);
            }

            print qq(<tr><td><div class="label">) . $fm->localise($info->{label}) ;
        
            # display errors (if any) below the field label.
            my $error = $fm->{errors}->{$info->{label}};
            $fm->print_field_error($error) if $error;
                    
            my $inputfield = $fm->build_inputfield($info);
            print  qq(</div></td> <td><div class="field">$inputfield</div></td></tr>);
        }
    }
}

=head2 call_subroutine_fragment($subroutine)

Calls a subroutine for use with the <SUBROUTINE> element.

=cut

sub call_subroutine_fragment {
    my ($self, $routine) = @_;

    $routine =~ s/\(\)$//;

    $self->debug_msg("Subroutine is $routine");

    my %sub = (
        package => $self->{calling_package},
        sub => $routine,
    );

    if (CGI::FormMagick::Sub::exists(%sub)) {
        $self->debug_msg("Subroutine exists");
        return CGI::FormMagick::Sub::call(%sub);
    } else {
        $self->debug_msg("Subroutine does not exist");
        return undef;
    }

}



=pod

=head2 gather_field_info($field) 

Gathers various information about a field and returns it as a hashref.

=begin testing

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

=end testing 

=cut

sub gather_field_info {
    my ($fm, $fieldinfo) = @_;

    my %f;
    foreach (qw( VALIDATION LABEL TYPE ID OPTIONS DESCRIPTION CHECKED
    	MULTIPLE SIZE SRC CONTENT)) {
	    $f{lc($_)} = $fieldinfo->{$_} if $fieldinfo->{$_};
    }

    # value defaults to what the user filled in, if they filled
    # something in on a previous visit to this field
    if ($fm->{cgi}->param($f{id})) {
        $f{value} = $fm->{cgi}->param($f{id});

    # are we calling a subroutine to find the value?
    } elsif ($fieldinfo->{VALUE} && $fieldinfo->{VALUE} =~ /\((.*)\)$/) {
        my @args = ();
        if (defined $1) {
            @args = split /,\s*/, $1;
        }
        $f{value} = $fm->do_external_routine($fieldinfo->{VALUE}, @args); 

    # otherwise, use VALUE attribute or default to blank.
    } else {
        my $default = ($fieldinfo->{TYPE} eq 'CHECKBOX' ? 1 : "");
        $f{value} = $fieldinfo->{VALUE} || $default; 
    }

    $fm->debug_msg("Field name is $f{id}");
    return \%f;
} 

=pod

=head2 build_inputfield ($fm, $forminfo)

Builds HTML for individual form fields. $forminfo is a hashref
containing information about the field. 

=for testing
my $i = $fm->gather_field_info($minimalist_fieldinfo_ref);
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

    # nasty hack required here to select the desired value if it's preset
        $inputfield =~ s/(<OPTION VALUE="$info->{value}")/$1 SELECTED/;

    } elsif ($info->{type} eq "RADIO") {
        $inputfield = $tagmaker->input_group(
            type  => $info->{type},
            name  => $info->{id},
            value => $info->{option_values},
            text  => $info->{option_labels} 
        );
    # nasty hack required here to select the desired value if it's preset
        $inputfield =~ s/(VALUE="$info->{value}")/$1 CHECKED/;

    } elsif ($info->{type} eq "CHECKBOX") {

        # figure out whether hte box should be checked or not
        my $user_input = $fm->{cgi}->param($info->{id});
        my $c;
        if (defined $user_input) {
            $c = $user_input ? 1 : 0;
        } else {
            $c = $info->{checked};  # get from XML spec
        }

        $inputfield = $tagmaker->input(
            type    => $info->{type},
            name    => $info->{id},
            value   => $info->{value},
            checked => $c,
        );

    } else {
        # map HTML::TagMaker's functions to the type of this field.
        my %translation_table = (
            TEXTAREA => 'textarea',
            CHECKBOX => 'input_field',
            TEXT     => 'input_field',
            PASSWORD => 'input_field',
	    FILE     => 'input_field',
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
$info->{option_values} and $info->{option_labels}

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
