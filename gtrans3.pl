#gtranslate v3
#http://code.google.com/apis/language/translate/v2/using_rest.html
#country codes: http://code.google.com/apis/language/translate/v2/using_rest.html#language-params
# to do: a big case with reverse translate !howtosay !comosedice, parsing the target 

use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use strict;
use LWP::UserAgent;
use URI::Escape qw( uri_escape );
use HTML::Entities;
use utf8;


#use Data::Dumper;

my %country = (
	translate => "en",
	traducir => "es",
	tradurre => "it",
	transcn => "zh-CN",
);

my %langcodes = (
	"af" => "Afrikaans","sq" => "Albanian","ar" => "Arabic", "be" => "Belarusian", "bg" => "Bulgarian",
	"ca" => "Catalan","zh-CN" => "Chinese Simp", "zh-TW" => "Chinese Trad", "hr" => "Croatian",
	"cs" => "Czech","da" => "Danish","nl" => "Dutch", "en" => "English","et" => "Estonian","tl" => "Filipino",
	"fi" => "Finnish","fr" => "French","gl" => "Galician","de" => "German","el" => "Greek","ht" => "Haititian Creole",
	"iw" => "Hebrew","hi" => "Hindi","hu" => "Hungarian","is" => "Icelandic","id" => "Idonesian","ga" => "Irish",
	"it" => "Italian","ja" => "Japanese","lv" => "Latvian", "lt" => "Lithuanian", "mk" => "Macedonian", 	"ms" => "Malay",
	"mt" => "Maltese","no" => "Norwegian","fa" => "Persian", "pl" => "Polish","pt" => "Portuguese","ro" => "Romanian",
	"ru" => "Russian","sr" => "Serbian","sk" => "Slovak", 	"sl" => "Slovenian","es" => "Spanish","sw" => "Swahili", "sv" => "Swedish",
	"th" => "Thai","tr" => "Turkish","uk" => "Ukranian", "vi" => "Vietnamese", "cy" => "Welsh","yi" => "Yiddish",
);



sub msg_pub {
	my($server, $text, $nick, $mask,$chan) = @_;
	do_translate($text, $chan, $server) if ($server->{tag} =~ /3dg|fnode|lia|gsg/ and $text =~ /^!tr((?:anslate)|(?:ducir)|(?:durre)|(?:nscn))/);
}

sub do_translate {
	my ($text, $chan, $server) = @_;
	my ($tra,$query) = $text =~ /^!(\w+) (.*)$/;

	if ( !$query ) {
		$server->command("MSG $chan !translate <whatever_to_english> | !traducir <cualquiercosa_a_español> | !tradurre <tutto in italiano> | !transcn <翻成中文>");
		return;
	}
	if ($query =~ /listcode$/i) {
		sayit($server, $chan, "list of languages codes: http://goo.gl/KhFpu");
		return;
	}

	my $query8 = uri_escape($query);
	my $target8 = uri_escape($country{$tra});
	my $key = Irssi::settings_get_str('google_apikey');
	my $queryurl = "https://www.googleapis.com/language/translate/v2?key=";

	$queryurl .= $key if ($key);
	$queryurl .= "&target=" . $target8 if ($target8);
	$queryurl .= "&q=" . $query8 if ($query8);

	my $ua = LWP::UserAgent->new();
	#$ua->agent('AppleWebKit/533.4 (KHTML, like Gecko) Safari/533.4');
	$ua->protocols_allowed( [ 'http', 'https'] );

	#print_msg("$queryurl");	
	my $got = $ua->get($queryurl);

	my $content = $got->decoded_content;
	my ($detected) = $content =~ m{"detectedSourceLanguage": "([^"]+)"};
	my ($translated) = $content =~ m{"translatedText": "([^"]+)"};
	
	if (!$translated) {
		sayit($server,$chan,"NSUFFICIENT DATA FOR A MEANINGFUL ANSWER");
		return;
	} 
	else {
		my $decoded = HTML::Entities::decode($translated);
		my $orig = "[" . $langcodes{$detected} . "]" if ($detected);
		sayit($server, $chan, "$orig significa: $decoded") if ($target8 =~ /(es)|(it)/i); 
		sayit($server, $chan, "$orig means: $decoded") if ($target8 eq 'en');
		sayit($server, $chan, "$orig 意思是: $decoded") if ($target8 eq 'zh-CN');
		return;
	}
}
sub sayit { 
        my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}                                         
sub print_msg { active_win()->print("@_"); }
Irssi::signal_add("message public","msg_pub");
Irssi::settings_add_str('gtranslate', 'google_apikey', '');


