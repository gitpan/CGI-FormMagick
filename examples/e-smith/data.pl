#!/usr/local/bin/perl -w

use strict;
use CGI::FormMagick;

undef $/;
my $data = <DATA>;

my $fm = new CGI::FormMagick(
	TYPE => "STRING",
	SOURCE => "$data",
	DEBUG => 1
);

$fm->add_lexicon( "fr", lexicon_fr() );
$fm->display();

# list of mailcheck frequencies

sub mailcheck_frequencies {
	#return {
		#never 		=> "Not at all",
		#every5min 	=> "Every 5 minutes",
		#every15min 	=> "Every 15 minutes",
		#every30min 	=> "Every 30 minutes",
		#everyhour 	=> "Every hour",
		#every2hrs 	=> "Every 2 hours"
	#};
	return [
		"Not at all",
		"Every 5 minutes",
		"Every 15 minutes",
		"Every 30 minutes",
		"Every hour",
		"Every 2 hours"
	];
}

sub post_Retrieval_page {
	my $cgi = shift;
	if ($cgi->param("retrieval_mode") eq "Standard") {
		# skip to end
		$cgi->param(-name => "wherenext", -value => "Finish");
	} else {
		# go to ETRNMultiDropOptions page
		$cgi->param(-name => "wherenext", -value => "ETRNMultiDropOptions");
	}
	return 1;
}

sub post_ETRNMultiDropOptions_page {
	my $cgi = shift;
	if ($cgi->param("retrieval_mode") eq "Multi-drop") {
		# go to MultiDropOptions page
		$cgi->param(-name => "wherenext", -value => "MultiDropOptions");
	} else {
		# skip to end
		$cgi->param(-name => "wherenext", -value => "Finish");
	}
	return 1;
}

sub post_MultiDropOptions_page {
	my $cgi = shift;
	if ($cgi->param("sort_method") eq "Default") {
		# skip to end
		$cgi->param(-name => "wherenext", -value => "Finish");
	} else {
		# go to MultiDropSortHeader page
		$cgi->param(-name => "wherenext", -value => "MultiDropSortHeader");
	}
}

sub update_email_settings {
	my $cgi = shift;
	print qq(
	<h2>Finished</h2>
	<p>
	If we were really doing stuff here, this is the routine where
	we'd call the appropriate e-smith event to actually update the
	email settings.  Some of the values filled in by the user
	include:
	</p>
	);
	foreach my $f ( qw(retrieval_mode delegate_server) ) {
		print "<p><b>$f: </b>", $cgi->param($f), "</p>";
	}
	return 1;
}

# add phrases to be localised here

sub lexicon_fr {
	return {
		"foo" => "bar",
		"POP user account" => "compte d'utilisateur POP",
	};
}


__DATA__

<FORM TITLE="e-smith demo application" HEADER="head.tmpl" 
  FOOTER="foot.tmpl" POST-EVENT="update_email_settings">
  <PAGE NAME="Retrieval" TITLE="Change email retrieval settings" 
  POST-EVENT="post_Retrieval_page">
    <FIELD ID="retrieval_mode" LABEL="Email retrieval mode" TYPE="SELECT" 
      OPTIONS="'Standard','ETRN','Multi-drop'" VALIDATION="nonblank"
      DESCRIPTION="The mail retrieval mode can be set to standard (for
      dedicated Internet connections), ETRN (recommended for dialup
      connections), or multi-drop (for dialup connections if ETRN is not
      supported by your Internet provider)."/>
    <FIELD ID="delegate_server" LABEL="Delegate mail server" TYPE="TEXT" 
      DESCRIPTION="Your e-smith system includes a
      complete, full-featured email server. However, if for some reason
      you wish to delegate email processing to another system, specify
      the IP address of the delegate system here. For normal operation,
      leave this field blank."/>
  </PAGE>
  <PAGE NAME="ETRNMultiDropOptions" TITLE="ETRN and Multi-drop Options"
  POST-EVENT="post_ETRNMultiDropOptions_page">
    <FIELD ID="secondary_server" LABEL="Secondary mail server" TYPE="TEXT" 
      VALIDATION="domain_name" DESCRIPTION="As you are using ETRN or
      Multi-drop, you must specify the hostname or IP address of your
      secondary mail server."/>
    <FIELD ID="office_hours_frequency" LABEL="During office hours
    (8:00am to 6:00pm on weekdays)" TYPE="SELECT" 
      OPTIONS="mailcheck_frequencies()" VALIDATION="nonblank"
      DESCRIPTION="You can control how frequently the e-smith server and
      gateway contacts your secondary email server to fetch email. More
      frequent connections mean that you receive your email more
      quickly, but also cause Internet requests to be sent more often,
      possibly increasing your phone and Internet charges."/>
    <FIELD ID="outside_office_hours_frequency" LABEL="Outside office
    hours on weekdays" TYPE="SELECT" 
      OPTIONS="mailcheck_frequencies()" VALIDATION="nonblank"/>
    <FIELD ID="weekend_frequency" LABEL="During the weekend" TYPE="SELECT" 
      OPTIONS="mailcheck_frequencies()" VALIDATION="nonblank"/>
  </PAGE>
  <PAGE NAME="MultiDropOptions" TITLE="Multi-drop Options"
  POST-EVENT="post_MultiDropOptions_page">
  DESCRIPTION="As you are using multi-drop email, you must specify the
  POP user account and password. Also, you can either use the default
  e-smith server and gateway mail sorting method, or you can specify a
  particular message header to use for mail sorting.">
    <FIELD ID="pop_user_account" LABEL="POP user account" TYPE="TEXT" 
      VALIDATION="nonblank"/>
    <FIELD ID="pop_user_account" LABEL="POP user password" TYPE="TEXT" 
      VALIDATION="nonblank"/>
    <FIELD ID="sort_method" LABEL="Sort method" TYPE="SELECT" 
      OPTIONS="'Default','Choose your own'" VALIDATION="nonblank"/>
  </PAGE>
  <PAGE NAME="MultiDropSortHeader" TITLE="Multi-drop Sort Header">
    <FIELD ID="multi_drop_sort_header" LABEL="Specify a header to sort by" 
      TYPE="TEXT" VALIDATION="nonblank"/>
  </PAGE>
</FORM>
