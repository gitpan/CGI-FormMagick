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
# $Id: FormMagick.pm,v 1.35 2001/03/13 22:26:59 skud Exp $
#

package    CGI::FormMagick;
require    Exporter;
@ISA     = qw(Exporter);
@EXPORT  = qw(new display);

my $VERSION = $VERSION = "0.4.0";

use XML::Parser;
use Text::Template;
use CGI::Persistent;
use CGI::FormMagick::TagMaker;
use CGI::FormMagick::Validator;
use CGI::FormMagick::L10N;

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

=cut

sub new {
  shift;
  my $self 		= {};
  my %args 		= @_;

  $self->{debug} 		= $args{DEBUG} 		|| 0;
  $self->{inputtype} 		= uc($args{TYPE}) 	|| "FILE";

  foreach (qw(PREVIOUSBUTTON RESETBUTTON STARTOVERLINK)) {
    if (exists $args{$_}) {
      $self->{lc($_)} = $args{$_};
    } else {
      $self->{lc($_)} = 1;
    }
  }	

  my $p = new XML::Parser (Style => 'Tree');

  if ($self->{inputtype} eq "FILE") {
    if ($args{SOURCE}) {
      $self->{source} = $args{SOURCE};
    } else {
      # default source filename to the same as the perl script, with .xml 
      # extension
      use File::Basename;
    
      my($scriptname, $scriptdir, $extension) =
         File::Basename::fileparse($0, '\.[^\.]+');
    
      my $string = $scriptname . '.xml';
      $self->{source} = $string;
    }

    $self->{xml} = $p->parsefile($self->{source});
  } elsif ($self->{inputtype} eq "STRING") {
    $self->{source} = $args{SOURCE};
    $self->{xml} = $p->parse($self->{source});
  }

  # okay, this XML::Parser data structure is a little strange. 
  # perldoc XML::Parser gives some help, but here's a crib sheet: 
  
  # $self->{xml}[0] is "form", the name of the root element,
  # $self->{xml}[1] is the actual contents of the "form" element.
  # $self->{xml}[1][0] is the attributes of the "form" element.
  # $self->{xml}[1][4] is the first page. 
  # $self->{xml}[1][8] is the second page.
  # $self->{xml}[1][8][4] is the first field of the second page.  

  # debugging statements, use these to figure out for yourself 
  #   how the parse tree works. 
  #use Data::Dumper;
  # print Dumper( $self->{xml}) ;
  # print Dumper( $self->{xml}[1][0]) ;
  #print Dumper( $self->{page_object} );

  # figure out what language we're using
  $self->{language} = CGI::FormMagick::L10N->get_handle()
        || die "Can't find an acceptable language module.";

  # use the user-defined session handling directory (or default to
  # session-tokens) to store session tokens
  if ($args{SESSIONDIR}) {
	  $self->{sessiondir} = $args{SESSIONDIR};
  } else {
    require File::Basename;

    my($scriptname, $scriptdir, $extension) =
      File::Basename::fileparse($0, '\.[^\.]+');

    $self->{sessiondir} = "$scriptdir/session-tokens";
  }
  	
  $self->{calling_package} = (caller)[0]; 

  bless $self;
  return $self;

}

#----------------------------------------------------------------------------
# display()
#
# Displays the current form page
#----------------------------------------------------------------------------

=pod

=head2 display()

The display method displays your form.  It takes no arguments.

=cut

sub display {
  my $self = shift;

  local $^W = 0;
  # create a session-handling CGI object
  my $cgi = new CGI::Persistent $self->{sessiondir};
  $^W = 1;

  print $cgi->header;

  # debug thingy, to check L10N lexicons, only if you need it
  check_l10n($self) if $cgi->param('checkl10n');

  # pick up page number from CGI, else default to 1
  $self->{page_number} = $cgi->param("page") || 1;
  $self->debug("The current page number is $self->{page_number}");

  $self->{page_stack} = $cgi->param("page_stack") || "";
  $self->debug("The page stack is currently $self->{page_stack}");

  $self->{page_object} = $self->{xml}[1][ $self->{page_number} * 4 ];
  $self->debug("The current page object is $self->{page_object}");

  # Check whether they clicked "Previous" or something else
  # If they clicked previous, we avoid validation etc.  See
  # doc/pageflow.dia for details

  my %errors;

  if (not $cgi->param("wherenext")) {
    # do nothing ... we want the first page
  } elsif ($cgi->param("wherenext") eq "Previous") {
    $self->{page_number} = $self->pop_page_stack();
  } else {
    # We ONLY validate when they click Next (well, not Previous, anyway) 
    %errors = validate_page($self, $cgi, $self->{page_object});
  
    unless (%errors) {
      # ONLY do the page post event if the form passes validation
      $self->page_post_event($cgi); 
  
      # increment page_number if the user clicked "Next" 
      # or, if the user has explicitly set the "wherenext" param we
      # figure out what page they meant by passing the name to the
      # find_page_by_name() routine
     
      if ($cgi->param("wherenext") eq "Next" or 
	      ($cgi->param(".id") and not $cgi->param("wherenext"))) {

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
      } elsif ($cgi->param("wherenext") eq "Finish") {
        # nothing! (see below)
      } else { 
        $self->push_page_stack($self->{page_number});
        $self->{page_number} = find_page_by_name($self, $cgi->param("wherenext"));

        # TODO: find_page_by_name will now return undef if it can't find the page.
        # do we need to fix this line above?
      }
    }
  }

  # OK, now we're preparing to display the next page

  # multiply page number by 4 to get the array index of where the page
  # description is... yes, it's ugly, but that's just how the parse tree
  # is with XML::Parser

  $self->debug("The new page number is $self->{page_number}");
  $self->debug("The new page stack is $self->{page_stack}");
  $self->{page_object} = $self->{xml}[1][ $self->{page_number} * 4 ];
  $self->debug("The new page object is $self->{page_object}");

  # We do the form pre-event if we're on page 1, BUT only if it's
  # the first time we've displayed it.  We can tell that by the fact
  # that there's no "page" parameter in the CGI, since that tells us
  # where we've just come from.  In other words, we don't do the
  # form pre-event if someone clicked "Previous" on page 2.

  $self->form_pre_event($cgi) 
      if (($self->{page_number} == 1) and not ($cgi->param("page")));

  # we ALWAYS do the page pre-event on the new page
  $self->page_pre_event($cgi); 
  
  $self->print_form_header();

  # if we're finished with the form, do form-ending things
  if ($cgi->param("wherenext") eq "Finish" and not %errors) {
	$self->form_post_event($cgi);
  } else {
    $self->print_page_header($cgi);

    display_fields($self, $cgi, %errors);

    $self->print_buttons();
    $self->print_page_footer($cgi);
  }

  $self->print_form_footer($cgi);
}

#----------------------------------------------------------------------------
# pop_page_stack($self)
#
# pops the last page off the stack of pages a user's visited... used
# when the user clicks "Previous"
#
# removes the last element from the stack (modifying it in place in
# $self->{page_stack}) and returns the element it removed
#
# eg: 
# if the CGI "pagestack" parameter is "1,2,3,5"...
# my $page = $self->pop_page_stack();
# $self->{page_stack} will be 1,2,3
# $page will be 5
#----------------------------------------------------------------------------

sub pop_page_stack {
	my $self = shift;
	my @pages = split(",", $self->{page_stack});
	my $lastpage = pop(@pages);
	$self->{page_stack} = join(",", @pages);
	return $lastpage;
}

#----------------------------------------------------------------------------
# push_page_stack($stack, $newpage)
#
# push a new page onto the page stack that keeps track of where a user
# has been.
#----------------------------------------------------------------------------

sub push_page_stack {
	my $self = shift;
	my $newpage = shift;
	$self->{page_stack} = "$self->{page_stack},$newpage";
	$self->{page_stack} =~ s/^,//;
}

#----------------------------------------------------------------------------
# print_buttons($self)
#
# print the table row containing the form's buttons
#----------------------------------------------------------------------------

sub print_buttons {
  my $self = shift;	
  print qq(<tr><td></td><td class="buttons">);
  print qq(<input type="submit" name="wherenext" value="Previous">) 
  	unless $self->{page_number} == 1 or $self->{previousbutton} == 0;

  # check whether it's the last page yet
  if (scalar(@{$self->{xml}[1]} + 1)/4 == $self->{page_number}+1) {
    print qq(<input type="submit" name="wherenext" value="Finish">\n);
  } else {
    print qq(<input type="submit" name="wherenext" value="Next">\n);
  }
  print qq(<input type="reset" value="Clear this form">) 
  	if $self->{resetbutton};
  print qq(</tr>);
}

#----------------------------------------------------------------------------
# find_page_by_name($self, $name)
#
# find a page given the NAME attribute.  Returns the numeric index of
# the page, suitable for $wherenext.  That number needs to be multiplied
# by 4 to get at XML::Parser's representation of it.
#----------------------------------------------------------------------------

sub find_page_by_name {
	my $self = shift;
	my $name = shift;

  # $self->{xml}[1][0] is the attributes of the "form" element.
  # $self->{xml}[1][4] is the first page. 
  # $self->{xml}[1][8] is the second page.
  # $self->{xml}[1][8][4] is the first field of the second page.  
	
	for (my $i = 4; $i < scalar($self->{xml}[1]); $i += 4) { 
		debug($self, "Checking XML bit $i");
		debug($self, "Name is $self->{xml}[1][$i][0]->{NAME}");
		return $i/4 if $self->{xml}->[1][$i][0]->{NAME} eq "$name";
	}
	return undef;	# if you can't find that page	
}

#----------------------------------------------------------------------------
# get_page_by_number($self, $page_index)
#
# given a page index, return a ref to that page within $self.
# this is just here so we don't have to remember the crufty details
# of the XML::Parser data structure. 
#----------------------------------------------------------------------------

sub get_page_by_number {
	my ($self, $pagenum) = @_;
	
	return $self->{xml}[1][$pagenum * 4 ];

}

#----------------------------------------------------------------------------
# find_field_by_name($self, $name)
#
# find a page and field given the NAME attribute.  Returns the numeric index of
# the page and the numeric index of the field.  Those numbers need to be 
# multiplied  by 4 to get at XML::Parser's representation of it.
#----------------------------------------------------------------------------

sub find_field_by_name {
	my $self = shift;
	my $name = shift;

  	# $self->{xml}[1][0] is the attributes of the "form" element.
  	# $self->{xml}[1][4] is the first page. 
  	# $self->{xml}[1][8] is the second page.
  	# $self->{xml}[1][8][4] is the first field of the second page.  
	
	for (my $i = 4; $i < scalar($self->{xml}[1]); $i += 4) { 
		debug($self, "Checking XML bit $i");
		debug($self, "Name is $self->{xml}[1][$i][0]->{NAME}");
		for (my $j =4; $j < scalar($self->{xml}[1][$i]); $j += 4) {
			return ($i/4, $j/4) 
				if $self->{xml}->[1][$j][$i][0]->{NAME} eq "$name";
		}		
	}
	return undef;	# if you can't find it
}



#----------------------------------------------------------------------------
# display_fields($self, $cgi, %errors)
#
# displays the fields for a page by looping through them
#----------------------------------------------------------------------------

sub display_fields {
  my ($self, $cgi, %errors) = @_;

  # $self->{page_object} is a big array. To find info about field N,
  # access element 4*N . 
  
  my @fields;
  for (my $i=4; $i <= scalar @{$self->{page_object}}; $i=$i+4) {
    push (@fields, $self->{page_object}[$i][0] );
  }

  my @definitions;

  # HTML::TagMaker gives us an easy way to make form widgets.
  my $tagmaker = CGI::FormMagick::TagMaker->new();

  while (my $fieldinfo = shift @fields  ) {

    my $validation = $fieldinfo->{VALIDATION};
    my $label = $fieldinfo->{LABEL};
    my $type = $fieldinfo->{TYPE};
    my $fieldname = $fieldinfo->{ID};
    my $option_function = $fieldinfo->{OPTIONS};
    my $value;
    if ($cgi->param("$fieldname")) {
      $value = $cgi->param("$fieldname");
    } elsif ($fieldinfo->{VALUE} =~ /()$/) {
      $value = call_defaultvalue_routine($self, $cgi, $fieldinfo->{VALUE}); 
    } else {
      $value = $fieldinfo->{VALUE} || "";
    }

    my $description = $fieldinfo->{DESCRIPTION};
    my $checked = $fieldinfo->{CHECKED};
    my $multiple = $fieldinfo->{MULTIPLE};
    my $size = $fieldinfo->{SIZE};

    $self->print_field_description($description) if $description;
    
    my $inputfield;

    my $valueref;       # a hashref or arrayref returned by an options function
    my @option_values;  # values for an options list
    my @option_labels;  # displayed labels for an options list

    # if this is a grouped input (one with options), we'll need to
    # run the options function for it. 
    if (($type eq "SELECT") || ($type eq "RADIO")) {

      # DWIM whether the options are in a hash or an array.
      my $lv_hashref = $self->get_option_labels_and_values($cgi, $fieldinfo);

      @option_labels = @{$lv_hashref->{labels}};
      @option_values = @{$lv_hashref->{vals}};
	  
    }

	# make HTML for the form field. 
	$inputfield = $self->build_inputfield ({TYPE => $type, 
										  	FIELDNAME => $fieldname, 
										  	LABELS => [@option_labels],
						  					VALUES => [@option_values],
										  	LABEL => $label,
											VALUE => $value,
									  		TAGMAKER => $tagmaker,
					  						CHECKED => $checked,
											MULTIPLE => $multiple,
											SIZE=> $size});
	
	
    print qq(<tr><td class="label">) . $self->localise($label) ;
    
    # display errors below the field description.
    my $error = $errors{$label};
    print_field_error($error) if $error;
		
    print  qq(</td> <td class="field">$inputfield</td></tr>);

  }

}

#----------------------------------------------------------------------------
# print_form_header($self)
#
# prints the header template and the form title (heading level 1)
#----------------------------------------------------------------------------

sub print_form_header {
  my $self = shift;
  my $title = $self->{xml}[1][0]->{TITLE};

  # print out the templated headers (based on what's specified in the
  # HTML) then an h1 containing the FORM element's TITLE attribute
   
  print parse_template($self->{xml}[1][0]->{HEADER});
  print "<h1>", $self->localise($title), "</h1>\n";
}

#----------------------------------------------------------------------------
# print_form_footer($self, $cgi)
#
# prints the stuff that goes at the bottom of every page of the form
#----------------------------------------------------------------------------

sub print_form_footer {
  my $self = shift;
  my $cgi = shift;

  my $url = $cgi->url();
  
  # here's how we clear our state IDs
  print qq(<p><a href="$url">Start over again</a></p>) 
  	if $self->{startoverlink};

  # this is for debugging purposes
  $self->debug(qq(<a href="$url?checkl10n=1">Check L10N</a>));

  # print the footer template
  print parse_template($self->{xml}[1][0]->{FOOTER});
}


#----------------------------------------------------------------------------
# print_page_header($self)
#
# prints the page title (heading level 2) and description
#----------------------------------------------------------------------------

sub print_page_header {

  my $self = shift;
  my $cgi = shift;
  my $title       = $self->{page_object}[0]->{TITLE};
  my $description = $self->{page_object}[0]->{DESCRIPTION};

  # the level 2 heading is the PAGE element's TITLE heading
  print "<h2>", $self->localise($title), "</h2>\n";

  if ($description) {
	  print '<p class="pagedescription">', $self->localise($description), "</p>\n";
  }

  my $url = $cgi->url();
  print qq(<form method="POST" action="$url">\n);

  print qq(<input type="hidden" name="page" value="$self->{page_number}">\n);
  print qq(<input type="hidden" name="page_stack" value="$self->{page_stack}">\n);
  print $cgi->state_field(), "\n";	# hidden field with state ID

  print "<table>\n";
  
}

#----------------------------------------------------------------------------
# print_page_footer($self, $cgi)
#
# prints the stuff that goes at the bottom of a page, mostly just the
# form and table close tags and stuff.
#----------------------------------------------------------------------------

sub print_page_footer {
  my $self = shift;
  my $cgi = shift;
  
  print $cgi->state_field();
  print "</table>\n</form>\n";
}

#----------------------------------------------------------------------------
# print_field_description($description)
#
# prints the description of a field
#----------------------------------------------------------------------------

sub print_field_description {
	my $self = shift;
	my $d = shift;
	$d = $self->localise($d);
	print qq(<tr><td class="fielddescription" colspan=2>$d</td></tr>);
}


#----------------------------------------------------------------------------
# print_field_error($error)
#
# prints any errors related to a field
#----------------------------------------------------------------------------

sub print_field_error {
                my $e = shift;
                print qq(<br><div class="error" colspan=2>$e</div>);
}
                                                                                        
 
#----------------------------------------------------------------------------
# parse_template($filename)
#
# parses a Text::Template file and returns the result
#----------------------------------------------------------------------------

sub parse_template {
	my $filename = shift;
	carp("Template file $filename does not exist") unless -e $filename;
	my $template = new Text::Template (
		TYPE => 'FILE', 
		SOURCE => $filename
	);
	my $output = $template->fill_in();
	return $output;
}

#----------------------------------------------------------------------------
# localise($string)
#
# Translates a string into the end-user's preferred language by checking
# their HTTP_ACCEPT_LANG variable and pushing it through
# Locale::Maketext
#----------------------------------------------------------------------------

sub localise {
	my $self = shift;
	my $string = shift || "";
	if (my $localised_string = $self->{language}->maketext($string)) {
		return $localised_string;
	} else {
		warn "L10N warning: No localisation string found for '$string' for language $ENV{HTTP_ACCEPT_LANGUAGE}";
		return $string;
	}
}

=pod

=head2 add_lexicon()

This method takes two arguments.  The first is a two-letter string
representing the language to which entries should be added.  These are
standard ISO language abbreviations, eg "en" for English, "fr" for
French, "de" for German, etc.  

The second argument is a hashref in which the keys of the hash are the 
phrases to be translated and the values are the translations.

For more information about how localization (L10N) works in FormMagick,
see C<CGI::FormMagick::L10N>.

=cut

#----------------------------------------------------------------------------
# add_lexicon($lang, $lexicon_hashref)
#
# adds items to a language lexicon for localisation
#----------------------------------------------------------------------------

sub add_lexicon {
	my $self = shift;
	my ($lang, $lex_ref) = @_;

	# much reference nastiness to point to the Lexicon we want to change
	# ... couldn't have done this without Schuyler's help.  Ergh.

	no strict 'refs';
	my $changeme = "CGI::FormMagick::L10N::${lang}::Lexicon";

	my $hard_ref = \%$changeme;

	while (my ($a, $b) = each %$lex_ref) {
		$hard_ref->{$a} = $b;
	}
	use strict 'refs';

	#debug($self, "Our two refs are $hard_ref and $lex_ref");
	#debug($self, "foo is " . $self->localise("foo"));
	#debug($self, "Error is " . $self->localise("Error"));

}

=pod

=head2 debug($msg)

The debug method prints out a nicely formatted debug message.  It's
usually called from your script as C<$f->debug($msg)>

=cut

#----------------------------------------------------------------------------
# debug($msg)
#
# print a debug message.
#----------------------------------------------------------------------------

sub debug {
	my $self = shift;
	my $msg = shift;
	print qq(<p class="debug">$msg</p>) if $self->{debug};
}


#----------------------------------------------------------------------------
# check_l10n()
# print out lexica to check whether they're what you think they are
# this is mostly for debugging purposes
#----------------------------------------------------------------------------

sub check_l10n {
	my $self = shift;
	print qq( <p>Your choice of language: $ENV{HTTP_ACCEPT_LANGUAGE}</p>);
	my @langs = split(/, /, $ENV{HTTP_ACCEPT_LANGUAGE});
	foreach my $lang (@langs) {
		print qq(<h2>Language: $lang</h2>);

		no strict 'refs';
		my $lex= "CGI::FormMagick::L10N::${lang}::Lexicon";
		debug($self, "Lexicon name is $lex");
		debug($self, scalar(keys %$lex) . " keys in lexicon");
		foreach my $term (keys %$lex) {
			print qq(<p>$term<br>
				<i>$lex->{$term}</i></p>);
		}			
		use strict 'refs';
	}
}

#----------------------------------------------------------------------------
# parse_validation_routine ($validation_routine_name)
#
# parse the name of a validation routine into its name and its parameters.
# returns a 2-element list, $validator and $arg.
#----------------------------------------------------------------------------

sub parse_validation_routine {
	my ($validation_routine_name) = @_;
	
	my ($validator, $arg) = ($validation_routine_name =~ 
		m/
		^		# start of string
		(\w+)		# a word (--> $validator)
		(?:		# non-capturing (to group the (.*))
		\(		# literal paren
		(.*)		# whatever's inside the paren (--> $arg)
		\)		# literal close paren
		)?		# (.*) is optional (zero or one of them)
		$		# end of string
		/x );

	return ($validator, $arg);
}

#--------------------------------------------------------------------------
# do_validation_routine ($self, $validator, $arg)
#
# runs validation functions with arguments. 
#--------------------------------------------------------------------------

sub do_validation_routine {
  my ($self, $validator, $arg, $fielddata) = @_;
  my $result;

  my $cp = $self->{calling_package};

  # TODO: this could use some documentation.
  if ($arg) {
    $self->debug("Args found: $arg");
    if ($result = (eval "&${cp}::$validator('$fielddata', $arg)")) {
      $self->debug("Called user validation routine");
    } elsif ($result = (eval "&CGI::FormMagick::Validator::" 
          . "$validator('$fielddata', $arg)")) {
      $self->debug("Called builtin validation routine");
    } else {
      $self->debug("Eval failed: $@");
    }
  } else { 
    $self->debug("No args found");
    if ($result = (eval "&${cp}::$validator('$fielddata')")) {
      $self->debug("Called user validation routine");
    } elsif ($result = (eval "&CGI::FormMagick::Validator::" 
          . "$validator('$fielddata')")) {
      $self->debug("Called builtin validation routine");
    } else {
      $self->debug("Eval failed: $@");
    }
  }

  $self->debug("Validation result is $result");
  return $result;
}	


=pod

=head1 SECURITY CONSIDERATIONS AND METHODS FOR MANUAL VALIDATION

If you use page POST-EVENT or PRE-EVENT routines which perform code
which is in any way based on user input, your application may be
susceptible to a security exploit.

The exploit can occur as follows:

Imagine you have an application with three pages.  Page 1 has fields A,
B and C.  Page 2 has fields D, E and F.  Page 3 has fields G, H and I.

The user fills in page 1 and the data FOR THAT PAGE is validated before 
they're allowed to move on to page 2.  When they fill in page 2, the
data FOR THAT PAGE is validated before they can move on.  Ditto for page
3.  

If the user saves a copy of page 2 and edits it to contain an extra
field, "A", with an invalid value, then submits that page back to
FormMagick, the added field "A" will NOT be validated.

This is because FormMagick relies on the XML description of the page to
know what fields to validate.  Only the current page's fields are
validated, until the very end when all the fields are revalidated one
last time before the FORM POST-EVENT is run.  This means that we don't
suffer the load of validating everything every time, and it will work
fine for most applications.

However, if you need to run PAGE POST-EVENT or PRE-EVENT routines that
rely on previous pages' data, you should validate it manually in your
POST-EVENT or PRE-EVENT routine.  The following methods are used
internally by FormMagick for its validation, but may also be useful to
developers.

Note: this stuff may be buggy.  Please let us know how you go with it.

=head2 $fm->validate_field($cgi, $fieldname | $fieldref)

This routine allows you to validate a specific field by hand if you need
to.  It returns a string with the error message if validation fails, or
the string "OK" on success.

Examples of use:

This is how you'd probably call it from your script:

  if ($fm->validate_field($cgi, "credit_card_number") eq "OK")) { }

FormMagick uses references to a field object, internally:

  if ($fm->validate_field($cgi, $fieldref) eq "OK")) { }

(that's so that FormMagick can easily loop through the fields in a page;
you shouldn't need to do that)

=cut


#----------------------------------------------------------------------------
# validate_field($self, $cgi, $fieldname | $fieldref)
#
# validates end-user input for an individual field. 
#----------------------------------------------------------------------------

sub validate_field {
  my ($self, $cgi, $param) = @_; 

  #TODO: make this take fieldnames, not just fieldrefs.
  my $fieldinfo = $param;  # really, this needs expanding.

  my $validation = $fieldinfo->{VALIDATION};
  my $fieldname  = $fieldinfo->{ID};
  my $fieldlabel = $fieldinfo->{LABEL} || "";
  my $fielddata  = $cgi->param($fieldname);
    
  $self->debug("Working with field $fieldlabel, data $fielddata, validation attribute $validation");

  # just skip everything else if there's no validation to do.
  return "OK" unless $validation;

  my @results;
  # XXX argh! this split statement requires that we write validators like 
  # "lengthrange(4, 10), word" like "lengthrange(4,10), word" in order to 
  # work. Eeek. That's not how this should work. But it was even
  # more broken before (I changed a * to a +). 
  # OTOH, I'm not sure it's fixed now. --srl

  my @validation_routines = split( /,\s+/, $validation);
  # $self->debug("Going to perform these validation routines: @validation_routines");

  foreach my $v (@validation_routines) {
    my ($validator, $arg) = parse_validation_routine($v);
    my $result = $self->do_validation_routine ($validator, $arg, $fielddata);
    push (@results, $result) if $result ne "OK";
	
    # for multiple errors, put semicolons between the errors before
    # shoving them in a hash to return.    

    if (@results)   {
      my $formatted_result = join("; ", @results) . "." ;
      return $formatted_result if ($formatted_result ne ".");
    } 

  }
  return "OK";
}

=pod

=head2 $fm->validate_page($cgi, ($number | $name | $pageref))

This routine allows you to validate a single page worth of fields.  It
can accept either a page number (counting naturally from one, B<NOT> 
starting at zero), a page name, or a reference to a page object.  You'll
probably want to use the name or number; the page reference is used
internally by FormMagick's C<validate_all()> routine to loop through
all the pages in the form.

This routine returns a hash of errors, with the keys being the names of
fields which have errors and the values being the error messages.  You
can test for whether something's passed validation by testing for a true
return value.

Examples:

  my %errors = $fm->validate_page($cgi, 3);
  my %errors = $fm->validate_page($cgi, "CreditCardDetails");
  if (%errors) { ... }

=cut

#----------------------------------------------------------------------------
# validate_page($self, $cgi, ($number | $name | $ref) )
#
# validates end-user input for a page. Can take a page number, a page name,
# or a reference to a page as a param. Returns a hash of errors for all
# fields on the page that had errors.
#----------------------------------------------------------------------------

sub validate_page {

  my ($self, $cgi, $param) = @_;
  my $page_index;	# what page number is this?
  my $page_ref;     

  # XXX should these next 15 lines or so be their own sub?
  # DWIM with $param; handle gracefully if we got a name, number or ref
  if (int( $param) eq $param ) {
    $page_index = $param;
    $page_ref = get_page_by_number($self, $page_index);
  } elsif ( ref($param) ) {
    $page_ref = $param;
  } elsif ($page_index = find_page_by_name($self, $param) ) {
    $page_ref = get_page_by_number($self, $page_index);
  } else {
    $self->debug("Arg to validate_page wasn't a valid number, name, or pageref.");
  }

  $self->debug("Validating page $page_ref.");

  my @fields;
  my %errors;
 
  # walk through the fields on the given page
  for (my $i=4; $i <= (scalar(@{$page_ref})) ; $i += 4) {
	my $field = ${$page_ref}[$i][0] ;
	my $result = $self->validate_field($cgi, $field);
	unless ($result eq "OK") {
		$errors{$field->{LABEL}} = $result;
	}
  } 
  
  return %errors;
}

=pod

=head2 $fm->validate_all($cgi)

This routine goes through all the pages that have been visited (using
FormMagick's built-in page stack to keep track of which these are) and
runs C<validate_page()> on each of them.

It returns a hash the same as C<validate_page()>.

=cut

#-----------------------------------------------------------------------------
# validate_all($self, $cgi)
#
# validate end-user input for all pages that were filled out.
#-----------------------------------------------------------------------------

sub validate_all {
	my ($self, $cgi) = @_;

	my %errors;

	$self->debug("Validating all form input.");

	# Walk through all the pages on the stack and make sure
	# the data for their fields is still valid
	foreach my $pagenum ( (split(/,/, $self->{page_stack})), $self->{page_number} ) {
		# add the errors from this page to the errors from any other pages
		%errors = ( %errors, $self->validate_page($cgi, $pagenum) );
	}

	return %errors;
}


#-----------------------------------------------------------------------------
# list_error_messages(%errors)
# prints a list of error messages caused by validation failures
#-----------------------------------------------------------------------------

sub list_error_messages {
	my %errors = @_;
	print qq(<div class="error">\n);
	print qq(<h3>Errors</h3>\n);
	print "<ul>";

	foreach my $field (keys %errors) {
		print "<li>$field: $errors{$field}\n";
	}
	print "</ul></div>\n";
}

#----------------------------------------------------------------------------
# get_option_labels_and_values ($cgi, $fieldinfo)
#
# returns labels and values for fields that require them.
#----------------------------------------------------------------------------

sub get_option_labels_and_values {

	my ($self, $cgi, $fieldinfo) = @_;

	my @option_labels;		# labels for items in a list
	my @option_values;		# the values hidden behind those labels

    my $options_attribute = $fieldinfo->{'OPTIONS'} || "";
	#debug ($self, "options attribute is $options_attribute");
	my $options_ref = $self->parse_options_attribute($cgi, $options_attribute);
	my $err = join (" ", $options_ref);
	#debug ($self, $err);
	
	#print Dumper $options_ref;
	
	# DWIM with the data that came in from the XML file or the options function,
	# since we may have gotten an array or a hash for those values. 
    if (ref($options_ref) eq "HASH") {
      foreach my $k (sort keys %$options_ref) {
	    # the keys are labels, the values are values. 
        push @option_labels, $k;
        push @option_values, $options_ref->{$k};
		#debug ($self, $k);
		#debug ($self, $options_ref->{$k});
		
      }
    } elsif (ref($options_ref) eq "ARRAY") {
      # labels are the same as values here. this is not a mistake. 
	  @option_labels = @$options_ref;
      @option_values = @$options_ref;
    } else {
      debug($self, "Something weird's going on.");
	  return undef;
    }

	
	my $return_value = {labels => [@option_labels], vals => [@option_values]};
	
	return $return_value;
}


#-----------------------------------------------------------------------------
# build_inputfield ($self, $forminfo)
#
# builds HTML for individual form fields. $forminfo is a hashref. 
#-----------------------------------------------------------------------------

sub build_inputfield {
	my ($self, $forminfo) = @_;
	
 	my $type = $forminfo->{TYPE}; 
	my $fieldname = $forminfo->{'FIELDNAME'};
	my @option_labels = $forminfo->{LABELS};
	my @option_values = $forminfo->{VALUES};
	my $tagmaker = $forminfo->{'TAGMAKER'};
	my $checked = $forminfo->{'CHECKED'};
	my $value = $forminfo->{'VALUE'};
	my $label = $forminfo->{'LABEL'};
 	my $multiple = $forminfo->{'MULTIPLE'};
	my $size = $forminfo->{'SIZE'};
	
	#debug ($self, join(" ", @option_labels) );
	
	my $inputfield;		# HTML for a form input

	if ($type eq "SELECT") {

      # Make a select box.  Yes, the []s in the option_group() call are a 
	  # bit weird, but that's the syntax that works. -srl

		# don't specify a size if a size wasn't given in the XML
		if ($size ne "") { 
    		$inputfield = $tagmaker->select_start( 
				type => $type, 
				name => $fieldname,
				multiple => $multiple,
				size => $size )
		} else {
			$inputfield = $tagmaker->select_start( 
				type => $type, 
				name => $fieldname,
				multiple => $multiple,
				size => $size )
		}	
	    $inputfield = $inputfield . $tagmaker->option_group( 
	    								value => @option_values, 
		    							text => @option_labels,
									) .  $tagmaker->select_end;
    } elsif ($type eq "RADIO") {
	  	$inputfield = $tagmaker->input_group(type => "$type",
	  	name => $fieldname,
	 	value => @option_values,
		text => @option_labels );
    } elsif ($type eq "CHECKBOX") {
	    $inputfield = $tagmaker->input(type => "$type",
		name => $fieldname,
		value => $value,
		checked => $checked,
		text => $label);
    } else {
	    # map HTML::TagMaker's functions to the type of this field.
		my %translation_table = (
		     TEXTAREA => 'textarea',
		     CHECKBOX => 'input_field',
		     TEXT => 'input_field',
		);
        my $function_name = $translation_table{$type};
		# make sure no size gets specified if the size isn't given in the XML
	    if ($size ne "") {
			$inputfield = $tagmaker->$function_name(type => "$type",
							    name => "$fieldname",
							    value => "$value",
								size => "$size",
							    );
	    } else {
			$inputfield = $tagmaker->$function_name(type => "$type",
							    name => "$fieldname",
							    value => "$value",
							    );
		}
    }
	
 
	return $inputfield;

}


#-----------------------------------------------------------------------------
# parse_options_attribute($options_field)
#
# parses the OPTIONS attibute from a FIELD element and returns a
# reference to either a hash or an array containing the relevant data to
# fill in a SELECT box or a RADIO group.
#-----------------------------------------------------------------------------

sub parse_options_attribute {
  my $self = shift;
  my $cgi = shift;
  my $options_field = shift;

  # we need a reference to keep the options in, as we don't know if 
  # they'll be a list or a scalar.  When we've got what we want, we
  # can do a ref($options_ref) to find out what flavour we got.

  my $options_ref;

  if ($options_field =~ /=>/) {			# user supplied a hash	
	#debug ($self, "options_ref should be a hashref");
	$options_ref = { eval $options_field };	# make options_ref a hashref
  } elsif ($options_field =~ /,/) {		# user supplied an array
  	#debug ($self, "options ref should be an arrayref");
    $options_ref = [ eval $options_field ];	# make options_ref an arrayref
  } else {					# user supplied a sub name
    $options_field =~ s/\(.*\)$//;		# strip parens
	#debug ($self, "options ref should be call_options_routine");
    $options_ref = call_options_routine($self, $cgi, $options_field);
  }
  return $options_ref;
}

#-----------------------------------------------------------------------------
# call_options_routine($self, $cgi, $options_field)
# given the options field (eg OPTIONS="myroutine") call that routine
# returns a reference to a hash or array with the options list in it
#-----------------------------------------------------------------------------

sub call_options_routine {
  my $self = shift;
  my $cgi = shift;
  my $options_field = shift;

  # This sets up a reference to the sub that'll fill this SELECT
  # box with data. We need to pass this CGI object to it, in case
  # for some reason the function wants to use a submitted value
  # from the CGI in a database query that populates the SELECT.
  # It ends up looking something like \&main::get_select_options(\$cgi).
  # --srl
  my $cp = $self->{calling_package};
  my $voodoo = "\&$cp\:\:$options_field(\$cgi)"; 

  my $options_ref;

  unless ($options_ref = eval $voodoo) {
    # it seems like the right thing to do if there is no value list
    # returned is to barf out a warning and leave the list blank.
    debug ($self, "Couldn't obtain a value list from $voodoo for field");
    my $options_ref = "";
  }
  return $options_ref;
}

#-----------------------------------------------------------------------------
# call_defaultvalue_routine($self, $cgi, $default_field)
# given the default value field (eg "myroutine" in VALUE="myroutine"), 
# call that routine.
# returns a scalar with the default value for a field. 
#-----------------------------------------------------------------------------

# XXX: this is largely the same as call_options_routine. We might
# want to put those 2 functions together in the future. 
sub call_defaultvalue_routine{
  my ($self, $cgi, $default_field) = @_;

  $default_field =~ s/\(.*\)$//;		# strip parens, if there are any
  

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
  # It ends up looking something like \&main::get_value(\$cgi).
  # --srl
  my $voodoo = "\&$calling_package\:\:$default_field(\$cgi)"; 

  my $default_value;

  unless ($default_value = eval $voodoo) {
    # if the function doesn't exist, assume we want to use the raw string.
	debug ($self, "Couldn't obtain a value from $voodoo for field");
    my $default_value = $default_field;
  }
  return $default_value;
}


#-----------------------------------------------------------------------------
# form_pre_event($self, $cgi)
#
# performs the PRE-EVENT (if any) for the form.  Usually used to do
# setup for the application.
#-----------------------------------------------------------------------------

sub form_pre_event {
   my ($self, $cgi) = @_;

   # this is the routine where we call some routine that will
   # give us default data for the form, or otherwise
   # do things that need doing before the form is submitted.

    # find out what the form pre_event action is. 
    my $pre_form_routine = $self->{xml}[1][0]->{'PRE-EVENT'};
    my $cp = $self->{calling_package};

    my $voodoo = "\&$cp\:\:$pre_form_routine(\$cgi)"; 

    # if the pre_form_routine is defined in the calling file, 
    # it'll run. Otherwise, we'll give some simple display of the
    # variables that were submitted.

    unless (eval $voodoo) {
	debug($self, "<p>There was no pre-form routine.</p>\n")
    }

}

#-------------------------------------------------------------------------
# form_post_event($self, $cgi)
#
# performs validation and runs the POST-EVENT (if any) otherwise just
# prints out the data that the user input
#-------------------------------------------------------------------------

sub form_post_event {
    my ($self, $cgi) = @_;
    
    # we need to validate EVERY ONE of the form inputs to make
    # sure malicious attacks don't happen.   See also "SECURITY 
    # CONSIDERATIONS" in the perldoc for how to get around this :-/

    my %errors = $self->validate_all($cgi);

    if (%errors) {

      # XXX for no good reason, localise causes weird errors here 
      #print "<h2>", localise("Validation errors"), "</h2>\n";
      print "<h2>", "Validation errors", "</h2>\n";
      print "<p>", "These validation errors are probably evidence of an attempt to circumvent the data validation on this application.  Please start over again.", "</p>";
      list_error_messages(%errors);
    } else {
      $self->debug("Validation successful.");

      # find out what the form post_event action is. 
      my $post_form_routine = $self->{xml}[1][0]->{'POST-EVENT'};

      unless (do_external_routine($self, $cgi, $post_form_routine)) {
  
        # XXX for no good reason, localise causes weird errors here 
        #print "<p>", localise("The following data was submitted"), "</p>\n";
  
        print "<p>", "The following data was submitted", "</p>\n";
        print "<ul>\n";
        my @params = $cgi->param;
        foreach my $param (@params) {
          my $value =  $cgi->param($param);
          print "<li>$param: $value\n";
        }
        print "</ul>\n";
      }
    }
}

sub page_pre_event {
    my ($self, $cgi) = @_;
    $self->debug("This is the page pre-event.");
    $self->debug("The current page is $self->{page_object}.");
    if (my $pre_page_routine = $self->{page_object}[0]->{'PRE-EVENT'}) {
      $self->debug("The pre-routine is $pre_page_routine");
      do_external_routine($self, $cgi, $pre_page_routine);
    }
}

sub page_post_event {
    my ($self, $cgi) = @_;
    $self->debug("This is the page post-event.");
    if (my $post_page_routine = $self->{page_object}[0]->{'POST-EVENT'}) {
      $self->debug("The post-routine is $post_page_routine");
      do_external_routine($self, $cgi, $post_page_routine);
    }
}

sub do_external_routine {
	my $self = shift;	
	my $cgi = shift;	
	my $routine = shift || "";

	my $cp = $self->{calling_package};
	my $voodoo = "\&$cp\:\:$routine(\$cgi)"; 

	debug($self, "Voodoo is $voodoo");

	if (eval $voodoo) {
		return 1;
	} else {
		debug($self, "There was no routine defined.");
		return 0;
	}
}


=pod 

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

Fields must ALWAYS have an ID value. Optional parameters are:

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

The subroutine will be passed the $cgi object as an argument, so you can
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

=head1 SEE ALSO

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

