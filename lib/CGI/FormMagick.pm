#!/usr/bin/perl -w 
#
# FormMagick (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# This software is distributed under the same licenses as Perl; see
# the file COPYING for details.

#
# $Id: FormMagick.pm,v 1.56 2001/09/24 20:20:55 skud Exp $
#

package    CGI::FormMagick;

my $VERSION = $VERSION = "0.49";

use XML::Parser;
use Text::Template;
use CGI::Persistent;
use CGI::FormMagick::TagMaker;
use CGI::FormMagick::Validator;
use CGI::FormMagick::L10N;
use CGI::FormMagick::HTML;
use CGI::FormMagick::Setup;
use CGI::FormMagick::Events;
use CGI::FormMagick::Utils;

use strict;
use Carp;

=pod 

=head1 NAME

CGI::FormMagick - easily create CGI form-based applications

=head1 SYNOPSIS

  use CGI::FormMagick;

  my $f = new CGI::FormMagick();

  # all options available to new()
  my $f = new CGI::FormMagick(
      TYPE => FILE,  
      SOURCE => $myxmlfile, 
      DEBUG => 1
      SESSIONDIR = "/tmp/session-tokens"
      PREVIOUSBUTTON = 1,
      RESETBUTTON = 0,
      STARTOVERLINK = 0
  );

  # other types available
  my $f = new CGI::FormMagick(TYPE => STRING,  SOURCE => $data );

  $f->add_lexicon("fr", { "Yes" => "Oui", "No" => "Non"});

  $f->display();

=head1 DESCRIPTION

FormMagick is a toolkit for easily building fairly complex form-based
web applications.  It allows the developer to specify the structure of a
multi-page "wizard" style form using XML, then display that form using
only a few lines of Perl.

=head2 How it works:

You (the developer) provide at least:

=over 4

=item *

Form descriptions (XML)

=item *

HTML templates (Text::Template format) for the page headers and footers

=back

And may optionally provide:

=over 4

=item *

L10N lexicon entries 

=item *

Validation routines for user input data

=item *

Routines to run before or after a page of the form is displayed

=back

FormMagick brings them all together to create a full application.

=head1 METHODS

=head2 new()

The C<new()> method requires no arguments, but may take the following
optional arguments (as a hash):

=over 4

=item TYPE

Defaults to "FILE" (the only currently implemented type).  Eventually
we'll also allow such things as FILEHANDLE, STRING, etc (c.f.
Text::Template, which does this quite nicely).

=item SOURCE

Defaults to a filename matching that of your script, only with an
extension of .xml (we got this idea from XML::Simple).

=item DEBUG

Defaults to 0 (no debug output).  Setting it to 1 (or any other true
value) will cause debugging messages to be output.

=item PREVIOUSBUTTON

Defaults to 1 ("Previous" button is shown).

=item RESETBUTTON

Defaults to 1 ("Clear this form" button is shown).

=item STARTOVERLINK

Defaults to 1 ("Start over" link at the bottom of the page is shown).

=back

=begin testing
BEGIN: {
    use_ok('CGI::FormMagick');
    use vars qw($fm);
    use lib "lib/";
}

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
ok($fm->isa('CGI::FormMagick'), "fm object is what we expect");

=end testing

=cut

sub new {
    shift;
    my $self 		= {};
    my %args 		= @_;

    bless $self;

    $self->{debug} 	= $args{DEBUG} 		|| 0;
    $self->{inputtype} 	= uc($args{TYPE}) 	|| "FILE";
    $self->{source}     = $args{SOURCE};

    foreach (qw(PREVIOUSBUTTON RESETBUTTON STARTOVERLINK)) {
        if (exists $args{$_}) {
            $self->{lc($_)} = $args{$_};
        } else {
            $self->{lc($_)} = 1;
        }
    }	

    $self->{xml}       = $self->parse_xml();
    $self->{clean_xml} = $self->clean_xml();

    # figure out what language we're using
    $self->{language} = CGI::FormMagick::L10N->get_handle()
        || die "Can't find an acceptable language module.";
    $self->{language}->fail_with( sub { undef } );

    $self->{sessiondir} = initialise_sessiondir($args{SESSIONDIR});
    $self->{calling_package} = (caller)[0]; 

    return $self;
}
=pod

=head2 display()

The display method displays your form.  It takes no arguments.

=for testing
ok($fm->display(), "Display");

=cut

sub display {
    my $self = shift;
    
    {
        local $^W = 0;
        # create a session-handling CGI object
        $self->{cgi} = new CGI::Persistent $self->{sessiondir};
        $^W = 1;
    }

    print $self->{cgi}->header;

    # debug thingy, to check L10N lexicons, only if you need it
    $self->check_l10n() if $self->{cgi}->param('checkl10n');

    # pick up page number from CGI, else default to 1
    $self->{page_number} = $self->{cgi}->param("page") || 0;
    $self->debug("The current page number is $self->{page_number}");

    $self->{page_stack} = $self->{cgi}->param("page_stack") || "";
    $self->debug("The page stack is currently $self->{page_stack}");

    $self->debug("The current page object is " . $self->page());

    # Check whether they clicked "Previous" or something else
    # If they clicked previous, we avoid validation etc.  See
    # doc/pageflow.dia for details

    if (not $self->{cgi}->param("wherenext")) {
        # do nothing ... we want the first page
    } elsif ($self->{cgi}->param("wherenext") eq "Previous") {
        $self->{page_number} = $self->pop_page_stack();
    } else {
        $self->prepare_for_next_page();
    }

    $self->debug("The new page number is $self->{page_number}");
    $self->debug("The new page stack is $self->{page_stack}");
    $self->debug("The new page object is " . $self->page());

    # We do the form pre-event if we're on page 1, BUT only if it's
    # the first time we've displayed it.  We can tell that by the fact
    # that there's no "page" parameter in the CGI, since that tells us
    # where we've just come from.  In other words, we don't do the
    # form pre-event if someone clicked "Previous" on page 2.

    $self->form_pre_event() 
        if (($self->{page_number} == 1) and not ($self->{cgi}->param("page")));

    # we ALWAYS do the page pre-event on the new page
    $self->page_pre_event(); 
  
    $self->print_form_header();

    $self->print_rest_of_page();
}


=head1 FORMMAGICK XML TUTORIAL

=head2 Form descriptions

The following is an example of how a form is described in XML. More
complete examples can be found in the C<examples/> subdirectory in the
CGI::FormMagick distribution.

  <FORM TITLE="My form application" HEADER="myform_header.tmpl" 
    FOOTER="myform_footer.tmpl" POST-EVENT="submit_order">
    <PAGE NAME="Personal" TITLE="Personal details" DESCRIPTION="Please
    provide us with the following personal details for our records">
      <FIELD ID="firstname" LABEL="Your first name" TYPE="TEXT" 
        VALIDATION="nonblank"/>
      <FIELD ID="lastname" LABEL="Your surname" TYPE="TEXT" 
        VALIDATION="nonblank"/>
      <FIELD ID="username" LABEL="Choose a username" TYPE="TEXT" 
        VALIDATION="username" DESCRIPTION="Your username must
	be between 3 and 8 characters in length and contain only letters
	and numbers."/>
    </PAGE>
    <PAGE NAME="Payment" TITLE="Payment details"
    POST-EVENT="check_credit_card" DESCRIPTION="We need your full credit
    card details to process your order.  Please fill in all fields.
    Your card will be charged within 48 hours.">
      <FIELD ID="cardtype" LABEL="Credit card type" TYPE="SELECT" 
        OPTIONS="list_credit_card_types" VALIDATION="credit_card_type"
		MULTIPLE="NO"/>
      <FIELD ID="cardnumber" LABEL="Credit card number" TYPE="TEXT" 
        VALIDATION="credit_card_number"/>
      <FIELD ID="cardexpiry" LABEL="Expiry date (MM/YY)" TYPE="TEXT" 
        VALIDATION="credit_card_expiry"/>
    </PAGE>
    <PAGE NAME="Random" TITLE="Random fields">
      <FIELD ID="confirm" LABEL="Click here to confirm" TYPE="CHECKBOX"
        VALUE="confirm" CHECKED="0"/>
      <FIELD ID="color" LABEL="Choose a color" TYPE="RADIO"
        OPTIONS="'red', 'green', 'blue'"/>
    </PAGE>
  </FORM>

The XML must comply with the FormMagick DTD (included in the
distribution as FormMagick.dtd).  A command-line tool to test compliance
is planned for a future release.

=head2 Field parameters

Fields must ALWAYS have an ID value, which is a unique name for the
field. Optional parameters are:

=over 4

=item * LABEL (a short description)

=item * DESCRIPTION (a more verbose description)

=item * VALUE (see below)

=item * VALIDATION (a list of validation functions: see CGI::FM::Validator)

=item * VALIDATION-ERROR-MESSAGE

=item * TYPE (see below)

=item * OPTIONS (see below)

=item * CHECKED (for CHECKBOX fields, does this start off checked?)

=item * MULTIPLE (for SELECT fields, can user select more than one value?)

=item * SIZE (for SELECT fields, height; for TEXT and TEXTAREA fields, length)

=back

The following field types are supported:

=over 4

=item *

TEXT

=item *

TEXT (SIZE attribute is optional)

=item * 

SELECT (requires OPTIONS attribute, MULTIPLE and SIZE are optional)

=item *

RADIO (requires OPTIONS attribute)

=item *

CHECKBOX (CHECKED attribute is optional)

=back

=head2 Notes on parsing of VALUE attribute

If your VALUE attribute ends in parens, it'll be taken as a subroutine
to run.  Otherwise, it'll just be taken as a literal.

This will be literal:

    VALUE="username"

This will run a subroutine:

    VALUE="get_username()"

The subroutine will be passed the CGI object as an argument, so you can
use the CGI params to help you generate the value you need.

Your subroutine should return a string containing the value you want.

=head2 Notes on parsing of OPTIONS attribute

The OPTIONS attribute has automagical Do What I Mean (DWIM) abilities.
You can give it a value which looks like a Perl list, a Perl hash, or a
subroutine name.  For instance:

    OPTIONS="'red', 'green', 'blue'"

    OPTIONS="'ff0000' => 'red', '00ff00' => 'green', '0000ff' => 'blue'"

    OPTIONS="get_colors()"

How it works is that FormMagick looks for the => operator, and if it
finds it it evals the OPTIONS string and assigns the result to a hash.
If it finds a comma (but no little => arrows) it figures it's a list,
and evals it and assigns the results to an array.  Otherwise, it tries
to interpret what's there as the name of a subroutine in the scope of
the script that called FormMagick.

A few gotchas to look out for:

=over 4

=item * 

Make sure you quote strings in lists and hashes.  "red,blue,green" will
fail (silently) because of the barewords.

=item * 

Single-element lists ("red") will fail because the DWIM parsing doesn't
find a comma there and treats it as the name of a subroutine.  But then,
a single-element radio button group or select dropdown is pretty 
meaningless anyway, so why would you do that?

=item * 

Arrays will result in options being sorted in the same order they were
listed.  Hashes will be sorted by key using the default Perl C<sort()>.

=item * 

An anti-gotcha: subroutine names do not require the parens on them.
"get_colors" and "get_colors()" will work the same.

=back

=head1 INTERNAL, DEVELOPER-ONLY ROUTINES

The following routines are used internally by FormMagick and are
documented here as a developers' reference.  If you are using FormMagick
to develop web applications, you can skip this section entirely.

=cut


sub prepare_for_next_page {
    my ($self) = @_;
    # We ONLY validate when they click Next (well, not Previous, anyway) 
    $self->validate_page($self->{page_number});

    unless ($self->errors()) {
        # ONLY do the page post event if the form passes validation
        $self->page_post_event(); 

        # increment page_number if the user clicked "Next" 
        # or, if the user has explicitly set the "wherenext" param we
        # figure out what page they meant by passing the name to the
        # get_page_by_name() routine
 
        if ($self->{cgi}->param("wherenext") eq "Next" or 
            ($self->{cgi}->param(".id") and not $self->{cgi}->param("wherenext"))) {

# the latter part of that is to check for if people just hit "enter" on
# a page with only one field.  A weirdness in the HTML spec and/or 
# browser implementations thereof means that hitting "enter" on a 
# single-text-field form will submit the form without any value
# being passed.  Worse yet, at least one browser is reported to
# automatically choose the first submit button on the form, in our
# case "Previous", which is just WRONG but I can't see any way to
# work around that.

            $self->push_page_stack($self->{page_number});
            $self->{page_number}++;
        } elsif ($self->{cgi}->param("wherenext") eq "Finish") {
            # nothing! (see below)
        } else { 
            $self->push_page_stack($self->{page_number});
            $self->{page_number} = $self->get_page_by_name($self->{cgi}->param("wherenext"));

            # TODO: get_page_by_name will now return undef if it can't find the page.
            # do we need to fix this line above?
        }
    }
}

sub print_rest_of_page {
    my ($self) = @_;
    $self->debug("Printing rest of page");
    # if we're finished with the form, do form-ending things
    if ($self->{cgi}->param("wherenext") and $self->{cgi}->param("wherenext") eq "Finish" 
        and not $self->errors()) {
        $self->debug("Looks like we're finished, mopping up and doing post_event next");
	$self->form_post_event();
    } else { # the default: print this page's fields and stuff
        $self->debug("Just a normal page, let's get on with it.");
        $self->print_page_header();

        $self->display_fields();

        $self->print_buttons();
        $self->print_page_footer();
    }

    $self->print_form_footer();
}

=head2 get_option_labels_and_values ($fieldinfo)

returns labels and values for fields that require them, by running a
subroutine or whatever else is needed.  Returns a hashref containing:

    { labels => \@options_labels, $vals => \@option_values }

=for testing
TODO: {
    local $TODO = "writeme";
    ok($fm->get_option_labels_and_values($f), "get option labels and values");
    ok($fm->get_option_labels_and_values($f), "fail gracefully with empty/no options attribute");
}

=cut

sub get_option_labels_and_values {

    my ($self, $fieldinfo) = @_;

    my @option_labels;		# labels for items in a list
    my @option_values;		# the values hidden behind those labels

    $self->debug("Options attribute appears to be $fieldinfo->{options}");

    my $options_attribute = $fieldinfo->{'options'} || "";
  
    my $options_ref = $self->parse_options_attribute($options_attribute);
	
    # DWIM with the data that came in from the XML file or the options function,
    # since we may have gotten an array or a hash for those values. 
    if (ref($options_ref) eq "HASH") {
        foreach my $k (sort keys %$options_ref) {
            # the keys are the option field values, the values are the option text
            push @option_values, $k;
            push @option_labels, $options_ref->{$k};
        }
    } elsif (ref($options_ref) eq "ARRAY") {
        # labels are the same as values here. this is not a mistake. 
        @option_labels = @$options_ref;
        @option_values = @$options_ref;
        $self->debug("options ref is an array, with " .  scalar(@$options_ref) . " elements, which are " . join(", ", @$options_ref));
    } else {
        $self->debug("Something weird's going on.");
        return undef;
    }

    return {labels => \@option_labels, vals => \@option_values};
}

=pod

=head2 parse_options_attribute($options_field)

parses the OPTIONS attibute from a FIELD element and returns a
reference to either a hash or an array containing the relevant data to
fill in a SELECT box or a RADIO group.

=cut

sub parse_options_attribute {
    my ($self, $options_field) = @_;

    # we need a reference to keep the options in, as we don't know if 
    # they'll be a list or a scalar.  When we've got what we want, we
    # can do a ref($options_ref) to find out what flavour we got.

    my $options_ref;

    $self->debug("options field looks like $options_field");

    if ($options_field =~ /=>/) {			# user supplied a hash	
        $self->debug("options_ref should be a hashref");
        $options_ref = { eval $options_field };	# make options_ref a hashref
    } elsif ($options_field =~ /,/) {		# user supplied an array
        $self->debug("options ref should be an arrayref");
        $options_ref = [ eval $options_field ];	# make options_ref an arrayref
        $self->debug("we have " . scalar(@$options_ref) . " elements");
    } else {					# user supplied a sub name
        $self->debug("i think i should call an external routine");
        $options_field =~ s/\(.*\)$//;		# strip parens
        $options_ref = call_options_routine($self, $options_field);
    }
    return $options_ref;
}

=pod

=head2 call_options_routine($self, $options_field)

given the options field (eg OPTIONS="myroutine") call that routine
returns a reference to a hash or array with the options list in it

This sets up a reference to the sub that'll fill this SELECT
box with data. We need to pass this CGI object to it, in case
for some reason the function wants to use a submitted value
from the CGI in a database query that populates the SELECT.
It ends up looking something like \&main::get_select_options(\$self->{cgi}).

=cut

sub call_options_routine {
    my ($self, $options_field) = @_;

    my $cp = $self->{calling_package};
    $self->debug("Calling package is $cp, options field is $options_field");
    my $voodoo = "\&$cp\:\:$options_field(\$self->{cgi})"; 

    my $options_ref;

    unless ($options_ref = eval $voodoo) {
        # it seems like the right thing to do if there is no value list
        # returned is to barf out a warning and leave the list blank.
        debug ($self, "Couldn't obtain a value list from $voodoo for field");
        my $options_ref = "";
    }
    return $options_ref;
}

=pod

=head2 call_defaultvalue_routine($self, $default_field)

Given the default value field (eg "myroutine" in VALUE="myroutine"), 
call that routine.  Returns a scalar with the default value for a field. 

XXX: this is largely the same as call_options_routine. We might
want to put those 2 functions together in the future. 

=cut

sub call_defaultvalue_routine{
    my ($self, $default_field) = @_;

    $default_field =~ s/\(.*\)$//;	# strip parens, if there are any
  
    # we got here through N layers of call stack, so walk up the stack
    # N times. The 0th element of caller() is the package that's using
    # FormMagick.pm, eg "My::App". 
  
    # walk up the call stack until we find something that's not 
    # CGI::FormMagick. That's what we're looking for. 

    my $callstack_level = 0;
    while (caller($callstack_level) eq "CGI::FormMagick") {
        $callstack_level++;
    }
  
    my $calling_package = (caller($callstack_level))[0] || "";

    # This sets up a reference to the user-defined sub that returns
    # a default value for a field. 
    # It ends up looking something like \&main::get_value(\$self->{cgi}).
    # --srl
    my $voodoo = "\&$calling_package\:\:$default_field(\$self->{cgi})"; 

    my $default_value;

    unless ($default_value = eval $voodoo) {
    # if the function doesn't exist, assume we want to use the raw string.
        debug ($self, "Couldn't obtain a value from $voodoo for field");
        my $default_value = $default_field;
    }
    return $default_value;
}

=pod

=head2 do_external_routine($self, $routine)

=cut

sub do_external_routine {
    my $self = shift;	
    my $routine = shift || "";
    
    my $cp = $self->{calling_package};
    my $voodoo = "\&$cp\:\:$routine(\$self->{cgi})"; 
    
    debug($self, "Voodoo is $voodoo");
    
    if (eval $voodoo) {
    	return 1;
    } else {
    	debug($self, "There was no routine defined.");
    	return 0;
    }
}

=pod

=head1 SEE ALSO

CGI::FormMagick::Utils

CGI::FormMagick::Events

CGI::FormMagick::Setup

CGI::FormMagick::L10N

CGI::FormMagick::Validator

CGI::FormMagick::FAQ

=head1 BUGS

The VALIDATION attribute must be very carefully formatted, with spaces
between the names of routines but not between the arguments to a
routine.  See description above.

=head1 AUTHOR

Kirrily "Skud" Robert <skud@infotrope.net>

Contributors:

Shane R. Landrum <slandrum@turing.csc.smith.edu>

James Ramirez <jamesr@cogs.susx.ac.uk>

More information about FormMagick may be found at 
http://sourceforge.net/projects/formmagick/

=cut
