#!/usr/bin/perl -w

package CGI::FormMagick;
use I18N::LangTags;
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

WARNING WARNING WARNING: The internals of this routine will change 
significantly in version 0.60, when we remove Locale::Maketext from 
the equation.  However, its output should still be the same.  Just FYI.

=begin testing

BEGIN: {
    use_ok('CGI::FormMagick');
    use vars qw($fm);
    use lib "lib/";
}

$ENV{HTTP_ACCEPT_LANGUAGE} = 'fr,en,de';
my $fm = CGI::FormMagick->new(type => 'file', source => "t/lexicon.xml");
$fm->parse_xml();   # suck in lexicon without display()ing

is($fm->localise("yes"), "oui", "Simple localisation");
is($fm->localise("Hello"), "Bonjour", "Simple localisation");
is($fm->localise("xyz"), "xyz", "Attempted localisation of untranslated string");
is($fm->localise(""),    "",    "Fail gracefully on localisation of empty string");

=end testing

=cut

sub localise {
    my $fm = shift;
    my $string = shift || "";
    if (my $trans = $fm->{lexicon}->{$string}) {
        return $trans;
    } else {
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
    my @langs = split(/,/, $ENV{HTTP_ACCEPT_LANGUAGE});
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
        shift @stripped;
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
    my @langs;
    foreach my $lang (split (",", $ENV{HTTP_ACCEPT_LANGUAGE}))
    {
	$lang =~ /(\S+)/;
	push @langs, $1;
    }
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
