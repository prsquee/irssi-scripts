use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use strict;
use WebService::Google::Language;
use HTML::Entities;

#REST::Google::Translate->http_referer('http://www.google.com');
#
#my $res = REST::Google::Translate->new(
#q => 'hello world',
#langpair => 'en|it'
#);
my %country = (
	translate => "en",
	traducir => "es",
	tradurre => "it",
	tratest => "zh-CN",
);

sub msg_pub {
	my($server, $text, $nick, $mask,$chan) = @_;
	do_translate($text, $chan, $server) if ($server->{tag} =~ /3dg|fnode|lia|gsg/ and $text =~ /^!tra((?:nslate)|(?:ducir)|(?:durre)|(?:test))/);
}

sub do_translate {
	my ($text, $chan, $server) = @_;
#	my $text8 = encode("utf8", $text); 
	my ($tra,$query) = $text =~ /^!(\w+) (.*)$/;

	if ( !$query ) {
		$server->command("MSG $chan !translate <whatever_to_english> | !traducir <cualquiercosa_a_español> | !tradurre <tutto in italiano>");
		return;
	}
	my $dest = $country{$tra};
	$query = "'" . $query . "'";

	my $encquery = HTML::Entities::encode($query);

	my $service = WebService::Google::Language->new(
		'referer' => 'http://www.google.com',
		'src' => '', 
		'dest' => $dest,
		'TEXT' => 'text'
       	);

	my $result = $service->translate($query);
	if ($result->error) {
		my $code = $result->code;
		my $msg = $result->message;
		$server->command("MSG $chan error $code -> $msg");
	} 
	else {
		my $detected = $result->language;
		my $translation = $result->translation;
		my $decoded = HTML::Entities::decode($translation);

		if ($translation) {
			$server->command("MSG $chan [$detected] $decoded");
		} else {
			$server->command("MSG $chan detected [$detected], but fail!");
		}
	}
			


}
sub print_msg { active_win()->print("@_"); }
signal_add("message public","msg_pub");

