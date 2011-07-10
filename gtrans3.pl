use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use strict;
use HTML::Entities;
use LWP::UserAgent;
use JSON;
#use Encode;
use Crypt::SSLeay;
use URI::Escape qw( uri_escape );
use Data::Dumper;


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
	my ($tra,$query) = $text =~ /^!(\w+) (.*)$/;

	if ( !$query ) {
		$server->command("MSG $chan !translate <whatever_to_english> | !traducir <cualquiercosa_a_español> | !tradurre <tutto in italiano>");
		return;
	}
	my $query8 = uri_escape($query);
	my $target8 = uri_escape($country{$tra});

	#my $queryurl = "https://ajax.googleapis.com/ajax/services/language/translate/v2?key=AIzaSyCfQ9Rblh9t-phxHoGXuEqC4jnhf-vlvLM&q=" . $query8 . "&target=" . $target8;
	my $queryurl = "https://ajax.googleapis.com/ajax/services/language/translate";
#	print_msg(" | $queryurl | ");
#	return;
	my $ua = LWP::UserAgent->new();

	#$ua->agent('AppleWebKit/533.4 (KHTML, like Gecko) Safari/533.4');
	$ua->protocols_allowed( [ 'http', 'https'] );
	
	my $body = $ua->get($queryurl);

	#my $result = $body->decoded_content;
	my $a = Dumper($body);
	
	print_msg("$a");
	return;


#	$server->command("MSG $chan [$detected] $decoded");
#	$server->command("MSG $chan detected [$detected], but fail!");

}
sub print_msg { active_win()->print("@_"); }
signal_add("message public","msg_pub");

