#!/usr/bin/perl -w

package CGI::FormMagick;
use I18N::LangTags;
use Text::Template 'fill_in_string';
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(localise);

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
translations for your apps.  This is done using the <lexicon> XML
element, like so:

    <form>
        ...
    </form>

    <lexicon lang="fr">
        <entry>
            <base>Hello</base>
            <trans>Bonjour</trans>
        </entry>
    </lexicon>

Sometimes you need to substitute variables into the localised strings.  There
are three ways to do this:

  1. Substitute another lexicon entry by it's base name.  This substitution will     happen automagically:

    <lexicon lang="fr">
	<entry>
	    <base>This text includes a {$var}.</base>
	    <trans>A {$var} this text includes.</trans>
	</entry>
	<entry>
	    <base>var</base>
	    <trans>variable</trans>
	</entry>
    </lexicon>

  2. Use a custom method in your FormMagick subclass that returns a hash of
     variables for substitution.  This substitution will happen automagically
     if you use the 'params' attribute of the lexicon XML element, and define
     the named method in your FormMagick subclass:

    <lexicon lang="fr" params="getLexiconParams()">
	<entry>
	    <base>This text includes a {$var}.</base>
	    <trans>A {$var} this text includes.</trans>
	</entry>
    </lexicon>

    package MyFormMagick;
    our @ISA = ('CGI::FormMagick');
    sub getLexiconParams
    {
	return (var => "variable");
    }
    1;
    
  3. Pass a hashref to the localise() method.  This substitution will happen
     automagically if you pass the hashref as an additional parameter to the
     localise() method: 

    <lexicon lang="fr">
	<entry>
	    <base>This text includes a {$var}.</base>
	    <trans>A {$var} this text includes.</trans>
	</entry>
    </lexicon>

    ...
    my $text = 'This text includes a {$var}.';
    my $translated = $fm->localise($text, {var => 'variable'});
    ...

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

=head2 localise($string)

Translates a string into the end-user's preferred language by checking
their HTTP_ACCEPT_LANG variable and looking up a lexicon hash for that
language (if it exists).  If no translation can be found, returns the
original string untranslated.  

Takes the text to translate as the first argument, and optionally, a hashref of
variables for substitution as the second argument.

WARNING WARNING WARNING: The internals of this routine will change 
significantly in version 0.60, when we remove Locale::Maketext from 
the equation.  However, its output should still be the same.  Just FYI.

=begin testing

BEGIN: {
    use_ok('CGI::FormMagick');
    use vars qw($fm);
    use lib "lib/";
}

$ENV{HTTP_ACCEPT_LANGUAGE} = 'fr, en, de';
my $fm = CGI::FormMagick->new(type => 'file', source => "t/lexicon.xml");
$fm->parse_xml();   # suck in lexicon without display()ing

is($fm->localise("yes"), "oui", "Simple localisation");
is($fm->localise("Hello"), "Bonjour", "Simple localisation");
is($fm->localise("xyz"), "xyz", "Attempted localisation of untranslated string");
is($fm->localise(""),    "",    "Fail gracefully on localisation of empty string");

# Lexicon variable substitution tests
{
    package MyFormMagick;
    our @ISA = ('CGI::FormMagick');
    sub new {
	shift;
	my $self = CGI::FormMagick->new(@_);
	$self->{calling_package} = (caller)[0];
	return bless $self;
    }

    sub getLexiconParams {
	return (params_var => "'params' method variable");
    }
}

my $mfm = MyFormMagick->new(type=> 'file', source => "t/lexicon-params.xml");
$mfm->parse_xml();
is($mfm->localise('This text contains a {$var}.', {var => "variable"}),
    "A variable this text contains.", 
    "Lexicon variable substitution from hashref arg to localise()");
is($mfm->localise('This text contains a {$var}.'),
    "A lexicon variable this text contains.",
    "Lexicon variable substitution from lexicon entry");
is($mfm->localise('This text contains a {$params_var}.'),
    "A 'params' method variable this text contains.",
    "Lexicon variable substitution from 'params' subclass method"); 


=end testing

=cut

sub localise {
    my $fm = shift;
    my $string = shift || "";
    my $hashref = shift(@_) || {};
    my $text;
    my %params = (%{$fm->{lexicon}}, $fm->_get_lexicon_params(), %$hashref);
    if (my $trans = $fm->{lexicon}->{$string}) {
        $text = fill_in_string($trans, HASH=>\%params);
    } else {
        $text = fill_in_string($string, HASH=>\%params);
    }
    return $text;
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
    }
}

=head2 get_lexicon()

Attempts to find a suitable localisation lexicon for use, and returns it
as a hash.

=begin testing

my $lextest = CGI::FormMagick->new(
    type => "file", 
    source => "t/lexicon-merge.xml"
);

$lextest->parse_xml(); # suck in lexicon without display()ing

$ENV{HTTP_ACCEPT_LANGUAGE} = 'fr';
is($ENV{HTTP_ACCEPT_LANGUAGE}, 'fr', "Set HTTP_ACCEPT_LANGUAGE to 'fr'");
is($lextest->localise("Hello"), "Bonjour", "Retained info from first lexicon");
is($lextest->localise("yes"), "certainement", "Picked up info from second (merged) lexicon");

=end testing

=cut

sub get_lexicon {
    my $self = shift;
    my (@lexicons) = @_;

    my @preferred_languages = get_languages();

    my %lexicons;
    foreach my $lex (@lexicons) {
        $lexlang = $lex->[0]->{lang};

        # merge multiple lexicons of the same language
        if ($lexicons{$lexlang}) {
            $lexicons{$lexlang} = [ @{$lexicons{$lexlang}}, $lex ];
        } else {
            $lexicons{$lexlang} = [ $lex ];
        }
    }



    my %thislex = ();
    PL: foreach my $pl (@preferred_languages) {
        if ($lexicons{$pl}) {
            %thislex = $self->clean_lexicon(@{$lexicons{$pl}});
            last PL;
        }
    }
    return %thislex;
}

=head2 _set_lexicon_params(@lexicons)

Given a hash ref of lexicon attributes, find the 'params' attribute
containing a method that returns a params hash (if set), and save it as an
object attribute. 

=cut

sub _set_lexicon_params
{
    my $self = shift;
    my $lexicon = shift;

    return unless $lexicon->{params};

    push @{$self->{lexicon_params}}, $lexicon->{params};
}

=head2 _get_lexicon_params()

Return the merged params hash for the preferred lexicon.

=cut

sub _get_lexicon_params
{
    my $self = shift;
    
    my %params;
    foreach my $p (@{$self->{lexicon_params}})
    {
	%params = (%params, eval("\$self->$p") );
    }
    return %params;
}

=head2 clean_lexicon(@lexicons)

Given an array of messy lexicons, cleans them up into a nice neat hash of
base/translation pairs.

It's an array because you might have more than one lexicon for the same
langauge.  These get merged into one lexicon hash, so that the first
lexicon of a given language will be overridden by the second.

=cut

sub clean_lexicon {
    my $self = shift;
    my @dirty_lexicons = @_;
    my %return_lexicon;
    foreach my $dl (@dirty_lexicons) {
        # strip first element (the language) which is not needed
        my @stripped = @$dl;
	# grab params hash from the lexicon attributes
        $self->_set_lexicon_params(shift @stripped);
        my @entries = CGI::FormMagick->clean_xml_array(@stripped);
        foreach my $e (@entries) {
            $base  = $e->{content}->[4]->[2];
            $trans = $e->{content}->[8]->[2];
            if ($base && $trans) {
                $return_lexicon{$base} = $trans;
            }
        }
    }
    return %return_lexicon;
}

=head2 get_languages()

Picks up the preferred language(s) from $ENV{HTTP_ACCEPT_LANGUAGE}

=begin testing

my $fm = CGI::FormMagick->new();
$ENV{HTTP_ACCEPT_LANGUAGE} = "fr, de, en";
$fm->fallback_language("sv");
is($fm->fallback_language(), "sv", "Set fallback language");
my @langs = $fm->get_languages();
is($langs[1], "de", "pick up list of languages");
is($langs[$#langs], "sv", "pick up fallback language");

$ENV{HTTP_ACCEPT_LANGUAGE} = "en-US";
@langs = $fm->get_languages();
ok(grep(/^en$/, @langs), "pick up super-languages");

=end testing

=cut

sub get_languages {
    my $self = shift;
    my @langs = split ", ", $ENV{HTTP_ACCEPT_LANGUAGE};
    push @langs, map { I18N::LangTags::super_languages($_) } @langs;
    push @langs, $self->{fallback_language} if $self->{fallback_language};
    return @langs;
}


=head1 SEE ALSO

The general documentation for FormMagick (C<perldoc CGI::FormMagick>)

More information about FormMagick may be found at 
http://sourceforge.net/projects/formmagick/

=cut

1;
