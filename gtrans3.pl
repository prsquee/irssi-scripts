#gtranslate v3
#http://code.google.com/apis/language/translate/v2/using_rest.html
use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use strict;
use LWP::UserAgent;
use URI::Escape qw( uri_escape );
#use Data::Dumper;

my %country = (
	translate => "en",
	traducir => "es",
	tradurre => "it",
	transcn => "zh-CN",
);

sub msg_pub {
	my($server, $text, $nick, $mask,$chan) = @_;
	do_translate($text, $chan, $server) if ($server->{tag} =~ /3dg|fnode|lia|gsg/ and $text =~ /^!tra((?:nslate)|(?:ducir)|(?:durre)|(?:nscn))/);
}

sub do_translate {
	my ($text, $chan, $server) = @_;
	my ($tra,$query) = $text =~ /^!(\w+) (.*)$/;

	if ( !$query ) {
		$server->command("MSG $chan !translate <whatever_to_english> | !traducir <cualquiercosa_a_español> | !tradurre <tutto in italiano> | !transcn <翻成中文>");
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
	
	my $got = $ua->get($queryurl);

	my $content = $got->decoded_content;
	my $a = Dumper($content);
	print_msg("$a");
	my ($detected) = $content =~ m{"detectedSourceLanguage": "([^"]+)"};
	my ($translated) = $content =~ m{"translatedText": "([^"]+)"};

	sayit($server, $chan, "significa: $translated") if ($target8 =~ /(es)|(it)/i); 
	sayit($server, $chan, "means: $translated") if ($target8 eq 'en');
	sayit($server, $chan, "意思是: $translated") if ($target8 eq 'zh-CN');
	return;
}
sub sayit { 
        my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}                                         
sub print_msg { active_win()->print("@_"); }
Irssi::signal_add("message public","msg_pub");
Irssi::settings_add_str('gtranslate', 'google_apikey', '');


