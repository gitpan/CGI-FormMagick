#!/usr/bin/perl -w

use Locale::Maketext;

package CGI::FormMagick::L10N;
require Exporter;
@ISA = qw(Locale::Maketext Exporter);
@EXPORT = qw(add_lexicon check_l10n localise);

=pod
=head1 NAME

CGI::FormMagick::L10N - localization routines for FormMagick

=head1 SYNOPSIS

  use CGI::FormMagick::L10N;

=head1 DESCRIPTION

L10N (Localisation) is the name given to the process of providing
translations into another language.  The previous step to this is I18N
(internationalisation) which is the process of making an application
ready to accept the translations.

We've done the work of I18N for you, so all you have to do is provide
translations for your apps.

FormMagick uses the C<Locale::Maketext> module for L10N.  It stores its
translations for each language in a hash like this:

  %Lexicon = (
    "Hello"     => "Bonjour",
    "Click here"    => "Appuyez ici"
  );

You can add your own entries to any language lexicon using the
C<add_lexicon()> method (see C<CGI::FormMagick> for how to call that method).

Localisation preferences are picked up from the HTTP_ACCEPT_LANGUAGE 
environment variable passed by the user's browser.  In Netscape, you set
this by choosing "Edit, Preferences, Navigator, Languages" and then
choosing your preferred language.

Localisation is performed on:

=over 4

=item *

Form titles

=item *

Page titles and descriptions

=item *

Field labels and descriptions

=item *

Validation error messages

=back

If you wish to localise other textual information such as your HTML 
Templates, you will have to explicitly call the l10n routines.

=head1 USER METHODS

=head2 add_lexicon($lang, $lexicon_hashref)

This method is deprecated and will be removed in CGI::FormMagick 0.60 in
favour of an XML-based lexicon.

=begin testing
BEGIN: {
    use_ok('CGI::FormMagick');
    use vars qw($fm);
    use lib "./lib";
}

$ENV{HTTP_ACCEPT_LANGUAGE} = $ENV{LANG} = $ENV{LANGUAGE} = "fr";

ok ($fm = new CGI::FormMagick(TYPE => 'FILE', SOURCE => "t/simple.xml"), "created fm object");

ok( $fm->add_lexicon("fr", { "yes" => "oui" })     , "Simple add_lexicon");
ok( not($fm->add_lexicon("fr", "abc" ))  , "Non-hashref lexicon should fail");
ok( not($fm->add_lexicon("fr", (1,2,3))) , "Non-hashref lexicon should fail");
ok( not($fm->add_lexicon("fr", [1,2,3])) , "Non-hashref lexicon should fail");
TODO: {
    local $TODO = "Haven't yet implemented tests for non-existent languages";
    ok( not($fm->add_lexicon("xx", { yes => 'oui' }))     , "Non-existent language should fail");
}

=end testing

=cut

sub add_lexicon {

    warn "WARNING: add_lexicon is deprecated, and will be removed in FormMagick 0.60\n";

    my ($self, $lang, $lexicon_hashref) = @_;

    return undef unless ref($lexicon_hashref) eq "HASH";

    # much reference nastiness to point to the Lexicon we want to change
    # ... couldn't have done this without Schuyler's help.  Ergh.
    # XXX needs work, no doubt

    no strict 'refs';
    my $changeme = "CGI::FormMagick::L10N::${lang}::Lexicon"; 
    
    # XXX somewhere here we have to check if $changeme exists, but that's
    # *hard*

    my $hard_ref = \%$changeme;
    
    while (my ($a, $b) = each %$lexicon_hashref) {
        $hard_ref->{$a} = $b;
    }
    use strict 'refs';

    #debug($self, "Our two refs are $hard_ref and $lex_ref");
    #debug($self, "foo is " . $self->localise("foo"));
    #debug($self, "Error is " . $self->localise("Error"));
    return 1;
}




=head1 DEVELOPER METHODS 

These routines are for internal use only, and are probably not of
interest to anyone except FormMagick developers.

=head2 localise($string)

Translates a string into the end-user's preferred language by checking
their HTTP_ACCEPT_LANG variable and pushing it through
Locale::Maketext

WARNING WARNING WARNING: The internals of this routine will change 
significantly in version 0.60, when we remove Locale::Maketext from 
the equation.  However, its output should still be the same.  Just FYI.

=for testing
is($fm->localise("yes"), "oui", "Simple localisation");
is($fm->localise("xyz"), "xyz", "Attempted localisation of untranslated string");
is($fm->localise(""),    "",    "Fail gracefully on localisation of empty string");


=cut

sub localise {
    my $fm = shift;
    my $string = shift || "";
    ($string) = ($string =~ /(.*)/s);
    warn "String is $string\n";
    if (my $localised_string = $fm->{language}->maketext($string)) {
        return $localised_string;
    } else {
        warn "L10N warning: No localisation string found for '$string' for language $ENV{HTTP_ACCEPT_LANGUAGE}";
        return $string;
    }
}

=pod

=head2 check_l10n()

print out lexicons to check whether they're what you think they are
this is mostly for debugging purposes.  If you have DEBUG set to 1 in
your call to the new() method, you'll see a link at the bottom of each
page that says "Check L10N".  This is the subroutine that's called when
you follow that link.

=cut

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

=pod 

=head1 SEE ALSO

The general documentation for FormMagick (C<perldoc CGI::FormMagick>)

More information about FormMagick may be found at 
http://sourceforge.net/projects/formmagick/

=cut

1;
