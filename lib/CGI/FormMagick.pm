#!/usr/bin/perl -w # # FormMagick (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# This software is distributed under the same licenses as Perl; see
# the file COPYING for details.

#
# $Id: FormMagick.pm,v 1.86 2002/01/22 21:16:50 skud Exp $
#

package    CGI::FormMagick;

my $VERSION = $VERSION = "0.50";

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
use CGI::FormMagick::Sub;

use strict;
use Carp;

use constant 'FIRST_PAGENUM' => 0; 

use vars qw( $AUTOLOAD );

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

Defaults to "FILE".  "STRING" is also available, in which case you must
specify a SOURCE which is either a literal string or a scalar variable.

=item SOURCE

Defaults to a filename matching that of your script, only with an
extension of .xml (we got this idea from XML::Simple).

=back

=begin testing
BEGIN: {
    use_ok('CGI::FormMagick');
    use vars qw($fm);
    use lib "lib/";
}

ok(CGI::FormMagick->can('new'), "We can call new");
ok($fm = CGI::FormMagick->new(TYPE => 'FILE', SOURCE => "t/simple.xml"), "create fm object"); 
isa_ok($fm, 'CGI::FormMagick');

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
            warn("$_ as arg to new() is deprecated -- use accessor method instead\n");
            $self->{lc($_)} = $args{$_};
        } else {
            $self->{lc($_)} = 1;
        }
    }	

    $self->{xml}       = $self->parse_xml();

    # figure out what language we're using
    $self->{language} = CGI::FormMagick::L10N->get_handle()
        || die "Can't find an acceptable language module.";
    $self->{language}->fail_with( sub { undef } );

    $self->{sessiondir} = initialise_sessiondir($args{SESSIONDIR});
    $self->{calling_package} = (caller)[0]; 

    return $self;
}

=pod

=head2 previousbutton()

With no arguments, tells you whether the previousbutton will be
displayed or not.  If you give it a true argument (eg 1) it will set the
previous button to be displayed.  A false value (eg 0) will set it to
not be displayed.

=head2 nextbutton()

As for previousbutton, but affects the "Next" button.  NOTE: NYI.

=head2 finishbutton()

Ditto, NYI.

=head2 resetbutton()

Ditto.

=head2 startoverlink()

Ditto.

=head2 debug()

Turns debugging on/off.




=begin testing

is($fm->previousbutton, 1, "Previous button set on to begin with");
$fm->previousbutton(0);
is($fm->previousbutton, 0, "Previous button turned off");
$fm->previousbutton(1);
is($fm->previousbutton, 1, "Previous button turned on again");
$fm->previousbutton("");
is($fm->previousbutton, 0, "Previous button turned off with empty string");
$fm->previousbutton("a");
is($fm->previousbutton, 1, "Previous button turned on with true string");

is($fm->debug, 0, "Debug set off to begin with");
$fm->debug(1);
is($fm->debug, 1, "Debug turned on");
$fm->debug(0);

=end testing

=cut

sub AUTOLOAD {
    my ($self, $onoff) = @_;
    my ($called_sub_name) = ($AUTOLOAD =~ m/([^:]*)$/);
    $called_sub_name = lc($called_sub_name);
    my @flags = qw(
        previousbutton 
        nextbutton 
        finishbutton 
        resetbutton 
        startoverlink 
        debug
    );
    if (grep /^$called_sub_name$/, @flags) {
        if ($onoff) {
            $self->{$called_sub_name} = 1;
        } elsif (defined $onoff) {
            $self->{$called_sub_name} = 0;
        } else {
            return $self->{$called_sub_name};
        }
    }
}

=pod

=head2 sessiondir()

With no arguments, tells you the directory in which session tokens are
kept.

With a true value, set the session directory, in which session tokens are kept.  Defaults
to C<session-tokens> under the directory in which your CGI script is
kept, but you probably want to set it to something outside the web tree.

With a false (but defined) value, resets the session dir to its default
value.

=begin testing

like($fm->sessiondir, qr(/session-tokens/), "Session dir set on to begin with");
$fm->sessiondir("/tmp");
is($fm->sessiondir, "/tmp", "Session dir changed");
$fm->sessiondir(0);
like($fm->sessiondir, qr(/session-tokens/), "Session dir returned to default");

=end testing

=cut

sub sessiondir {
    my ($self, $sd) = @_;
    if ($sd) {
        $self->{sessiondir} = $sd;
    } elsif (defined $sd) {
        $self->{sessiondir} = "./session-tokens/";
    } else {
        return $self->{sessiondir};
    }
}


=pod

=head2 display()

The display method displays your form.  It takes no arguments.

=for testing
SKIP: {
    skip "Problems with CGI::Persistent", 1 unless 0;
    ok($fm->display(), "Display");
}

=cut

sub display {
    my $self = shift;
    
    {
        local $^W = 0;
        # create a session-handling CGI object
        $self->{cgi} = new CGI::Persistent $self->{sessiondir};
    }

    print $self->{cgi}->header;

    # debug thingy, to check L10N lexicons, only if you need it
    $self->check_l10n() if $self->{cgi}->param('checkl10n');

    # pick up page number from CGI, else default to 1
    $self->{page_number} = $self->{cgi}->param("page") || FIRST_PAGENUM;
    $self->debug_msg("The page number started out as $self->{page_number}");

    if (defined $self->{cgi}->param("page_stack")) {
        $self->{page_stack} = $self->{cgi}->param("page_stack")
    } else {
        $self->{page_stack} = "";
    }

    $self->debug_msg("The page stack started out as $self->{page_stack}");

    # Check whether they clicked "Previous" or something else
    # If they clicked previous, we avoid validation etc.  See
    # doc/pageflow.dia for details

    if ($self->{cgi}->param("Previous")) {
        $self->{page_number} = $self->pop_page_stack();
        $self->debug_msg("Going to previous page, the page number is now
        $self->{page_number} and the stack is $self->{page_stack}");
    } elsif ($self->just_starting) {
        $self->form_pre_event();
    } else { 
        $self->prepare_for_next_page();
    }

    $self->print_form_header();

    if ($self->finished()) {
	$self->validate_all();
	$self->form_post_event();
    } else {
        $self->page_pre_event(); 
        $self->print_page();
    }

    $self->print_form_footer();
    $self->clear_navigation_params(); 
    
} 

=head1 FORMMAGICK XML TUTORIAL

=head2 Form descriptions

The main thing you need to know to use FormMagick is the structure 
and syntax of FormMagick forms.  FormMagick is based on a "wizard" sort
of interface, in which one form has many pages, and each page has many
fields.  This is expressed as a nested hierarchy of XML elements.

The following is an example of how a form is described in XML. More
complete examples can be found in the C<examples/> subdirectory in the
CGI::FormMagick distribution.

  <FORM TITLE="My form application" POST-EVENT="submit_order">
    <PAGE NAME="Personal" TITLE="Personal details" />
      <DESCRIPTION>
        Please provide us with the following personal details for 
        our records
      </DESCRIPTION>
      <FIELD ID="firstname" LABEL="Your first name" TYPE="TEXT" 
        VALIDATION="nonblank"/>
      <FIELD ID="lastname" LABEL="Your surname" TYPE="TEXT" 
        VALIDATION="nonblank"/>
      <FIELD ID="username" LABEL="Choose a username" TYPE="TEXT" 
        VALIDATION="username" />
      <FIELD ID="color" LABEL="Choose a color" TYPE="RADIO"
        OPTIONS="'red', 'green', 'blue'"/>
    </PAGE>
    <PAGE NAME="Payment" TITLE="Payment details"
    POST-EVENT="check_credit_card" />
      <DESCRIPTION>
        We need your full credit card details to process your 
        order.  Please fill in all fields.  Your card will be 
        charged within 48 hours.
      </DESCRIPTION>
      <FIELD ID="cardtype" LABEL="Credit card type" TYPE="SELECT" 
        OPTIONS="list_credit_card_types" VALIDATION="credit_card_type"
		MULTIPLE="NO"/>
      <FIELD ID="cardnumber" LABEL="Credit card number" TYPE="TEXT" 
        VALIDATION="credit_card_number"/>
      <FIELD ID="cardexpiry" LABEL="Expiry date (MM/YY)" TYPE="TEXT" 
        VALIDATION="credit_card_expiry"/>
    </PAGE>
    <PAGE NAME="Confirmation" TITLE="Confirmation">
      <FIELD ID="confirm" LABEL="Click here to confirm" TYPE="CHECKBOX"
        VALUE="confirm" CHECKED="0"/>
    </PAGE>
  </FORM>

The XML must comply with the FormMagick DTD (included in the
distribution as FormMagick.dtd).  A command-line tool to test compliance
is planned for a future release.

Here is an explanation of the nesting of elements and the attributes
supported by each element.

=head1 FORMS

=head2 Form sub-elements

A form may contain the following elements:

=over 4

=item *

PAGE

=back

=head2 Form attributes

The following attributes are supported for forms:

=over 4

=item *

PRE-EVENT (a subroutine to run before the form is displayed)

=item *

POST-EVENT (a subroutine to run after the form is completed)

=back

=head2 Example

    <FORM PRE-EVENT="setup()" POST-EVENT="submit()>
        <PAGE> ... </PAGE>
        <PAGE> ... </PAGE>
        <PAGE> ... </PAGE>
    </FORM>

=head1 PAGES

=head2 Page sub-elements

A page may contain the following sub-elements:

=over 4

=item *

DESCRIPTION

=item *

FIELD

=back


=head2 Page attributes

The following attributes are supported for pages:

=over 4

=item * 

NAME (required)

=back

=head2 Example

    <PAGE NAME="RoomType" POST-EVENT="check_availability">
      <DESCRIPTION>
        Please provide us with details of your preferred room.
      </DESCRIPTION>
      <FIELD> ... </FIELD>
      <FIELD> ... </FIELD>
      <FIELD> ... </FIELD>
    </PAGE>


=head1 FIELDS

Fields are the most important part of the form definition.  Several
types of HTML fields are supported, and each one has various attributes
associated with it.

=head2 Field types

You can specify the type of HTML field to be generated using the TYPE
attribute:

    <FIELD TYPE="...">

The following field types are supported:

=over 4

=item TEXT 

A plain text field.  You may optionally use the SIZE attribute to modify
the size of the field displayed.  To restrict the length of data entered
by the user, use the maxlength() validation routine.

=item SELECT 

A dropdown list.  You must provide the OPTIONS attribute to specify the
contents of the list (see below for the format of this attribute).  If
you set the MULTIPLE attribute to 1, multiple selections will be
enabled.  The optional SIZE attribute sets the number of items displayed
at once.

=item RADIO 

Radio buttons allow users to choose one item from a group.  This field
type requires the OPTIONS attribute (as for SELECT, above).

=item CHECKBOX 

This field type provides a simple check box for yes/no questions.  The
CHECKED attribute is optional, but if set to 1 will make the checkbox
checked by default.

=item PASSWORD

The PASSWORD field type is like a TEXT field, but obscures the data
typed in by the user.

=item FILE

This field type allows the upload of a file by the user.

=back

=head2 Field sub-elements

The following elements may be nested within a field:

=over 4

=item * 

LABEL (a short description; required)

=item * 

DESCRIPTION (a more verbose description; optional)

=back


=head2 Other field attributes

Fields must ALWAYS have a TYPE (described in the previous section) and 
an ID attribute, which is a unique name for 
the field.  Each type of field may have additional required attributes,
and may support other optional attributes.

Here is a list of optional attributes for fields:

=over 4

=item VALUE 

A default value to fill in; see below for more information on the format
of this field.

=item VALIDATION 

a list of validation functions; see L<CGI::FormMagick::Validator> for more
information on this subject.

=item VALIDATION-ERROR-MESSAGE

an error message to present to the user if validation fails.
CGI::FormMagick::Validator provides one by default, but you may prefer
to override it.

=item OPTIONS 

A list of options required for a SELECT list or RADIO buttons; see below for 
more information on the format of this attribute.

=item CHECKED 

For CHECKBOX fields, used to make the box checked by default.  Defaults
to 0.

=item MULTIPLE 

For SELECT fields, used to allow the user to select more than one value.

=item SIZE 

For SELECT fields, height; for TEXT and TEXTAREA fields, length.

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

=head2 magic_wherenext

We allow FM users to set the C<wherenext> param explicitly in their code,
to do branching of program logic.  This routine checks to see if they
have a magic C<wherenext> param and returns it.  Gives undef if it's not
set.

=begin testing

use CGI;

$cgi = CGI->new({ wherenext => "foo" });
local $fm->{cgi} = $cgi;
is($fm->magic_wherenext(), "foo", "Found magic wherenext value");

=end testing

=cut

sub magic_wherenext {
    my $self = shift;
    return $self->{cgi}->param("wherenext");
}


=head2 prepare_for_next_page

This does all the things needed before going on to the next page.
Specifically, it validates the data from this page, and then if
validation was successful it puts the current page onto the page stack 
and then sets page_number to whatever page we should be visiting next.

=begin testing

#
# First we test what happens when the user clicks Next normally.
#

local $fm->{page_number} = 0;
local $fm->{page_stack}  = "";
local $fm->{cgi} = CGI->new({
    firstname => "Kirrily",    # this should validate successfully.
    Next      => 1,
}); 

$fm->prepare_for_next_page();
is($fm->{page_number}, 1, "Increment the page number when user clicks next");
is($fm->{page_stack}, 0, "Set page stack when user clicks next");

#
# Now we're going to see what happens when the user just hits Enter
#

local $fm->{page_number} = 0;
local $fm->{page_stack}  = "";
local $fm->{cgi} = CGI->new({
    firstname => "Kirrily",
}); 

$fm->prepare_for_next_page();
is($fm->{page_number}, 1, "Increment the page number when user presses enter");
is($fm->{page_stack}, 0, "Set page stack when user presses enter");

#
# What if there's a magic "wherenext" value set?
#

local $fm->{page_number} = 0;
local $fm->{page_stack}  = "";
local $fm->{cgi} = CGI->new({
    firstname => "Kirrily",
    wherenext => "More again",
});  

$fm->prepare_for_next_page();
is($fm->{page_number}, 2, "Branch when magic wherenext is set");
is($fm->{page_stack}, 0, "Set page stack when magic wherenext is set");

=end testing

=cut


sub prepare_for_next_page {
    my ($self) = @_;
    $self->validate_page($self->{page_number});

    unless ($self->errors()) {
        # ONLY do the page post event if the form passes validation
        $self->page_post_event(); 
 
        $self->push_page_stack($self->{page_number});
        if ($self->magic_wherenext()) {
            $self->{page_number} = 
                $self->get_page_by_name($self->magic_wherenext());
        } else {
            $self->{page_number}++;
        }
    }
    $self->debug_msg("The page number is now $self->{page_number}");
    $self->debug_msg("The page stack is now $self->{page_stack}");
}

=head2 get_option_labels_and_values ($fieldinfo)

returns labels and values for fields that require them, by running a
subroutine or whatever else is needed.  Returns a hashref containing:

    { labels => \@options_labels, $vals => \@option_values }

=for testing
TODO: {
    local $TODO = "writeme";
    local $^W = 0; # Until these tests are happy
    ok($fm->get_option_labels_and_values($f), "get option labels and values");
    ok($fm->get_option_labels_and_values($f), "fail gracefully with empty/no options attribute");
}

=cut

sub get_option_labels_and_values {

    my ($self, $fieldinfo) = @_;

    my @option_labels;		# labels for items in a list
    my @option_values;		# the values hidden behind those labels

    $self->debug_msg(
        "Options attribute appears to be '"
        . (defined $fieldinfo->{options} ? $fieldinfo->{options} : '')
    );

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
        $self->debug_msg("options ref is an array, with " .  scalar(@$options_ref) . " elements, which are " . join(", ", @$options_ref));
    } else {
        $self->debug_msg("Something weird's going on.");
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

    $self->debug_msg("options field looks like $options_field");

    if ($options_field =~ /=>/) {			# user supplied a hash	
        $self->debug_msg("options_ref should be a hashref");
        $options_ref = { eval $options_field };	# make options_ref a hashref
    } elsif ($options_field =~ /,/) {		# user supplied an array
        $self->debug_msg("options ref should be an arrayref");
        $options_ref = [ eval $options_field ];	# make options_ref an arrayref
        $self->debug_msg("we have " . scalar(@$options_ref) . " elements");
    } else {					# user supplied a sub name
        $self->debug_msg("i think i should call an external routine");
        $options_field =~ s/\(.*\)$//;		# strip parens
        $options_ref = $self->do_external_routine($options_field);
    }
    return $options_ref;
}

=head2 do_external_routine($self, $routine, @optional_args)

Runs an external routine, for whatever purpose (filling in default values
of fields, validation, etc).  If anything is in @optional_args, the
routine is called using those.  If @optional_args is ommitted, then
$self->{cgi} is passed.  Returns the return value of the routine, or
undef on failure.  Also emits a warning (to your webserver's error log,
most likely) if it can't run the routine.

The routine is always called in the package which called FormMagick
(usually main::, but possibly something else).

The CGI object is passed to your routine, so you can do stuff like
$cgi->param("foo") to it to find out CGI parameters and so on.

=begin testing

sub one  {
    return 1;
}

sub zero {
    return 0;
}

sub add_1 {
    my $sum = 1;
    $sum += $_ foreach @_;
    return $sum;
};

foreach my $expectations (
    { expected => 1,     call_this => 'one' },
    { expected => 0,     call_this => 'zero' },
    { expected => 1,     call_this => 'add_1', with_args => [ 0 ] },
    { expected => 2,     call_this => 'add_1', with_args => [ 1 ] },
    { expected => 6,     call_this => 'add_1', with_args => [ 2, 3 ] },

    # Error cases:
    { expected => undef, call_this => undef }, 
    { expected => undef, call_this => 'no_such_sub' }, 
    { expected => undef, call_this => 'not even possible' }, 
) {
    my $expected = $expectations->{expected};
    my $call_this = $expectations->{call_this};
    my @args =
        exists $expectations->{with_args}
            ? @{$expectations->{with_args}}
            : undef;

    my $actual;
    {
        local $^W = 0; # Because we feed this bad input on purpose.
        $actual = $fm->do_external_routine($call_this, @args);
    }

    my $arg_string;
    if (!defined $args[0]) {
        $arg_string = 'undef';
    } else {
        $arg_string = "'" . join("', '", @args) .  "'";
    }
    my $description = "do_external_routine($arg_string)";

    is($actual, $expected, $description);
}

=end testing

=cut

sub do_external_routine {
    my $self = shift;
    my $routine = shift || "";
    my @args = @_;
    scalar @args or push @args, $self->{cgi};

    $routine =~ s/\(.*\)$//; # strip parens, if there are any

    CGI::FormMagick::Sub::call(
        package => $self->{calling_package},
        sub => $routine,
        args => \@args
    );
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
