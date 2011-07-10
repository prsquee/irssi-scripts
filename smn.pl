#webfetchtitle 
use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use LWP::UserAgent;
use strict;

sub msg_pub {
	my($server, $text, $nick, $mask,$chan) = @_;
	do_temp($text, $chan, $server) if ($server->{tag} =~ /3dg|fnode|lia|gsg/ and $text =~ /^!temp$/);
}

sub do_temp {
	my ($text, $chan, $server, $urlmatch) = @_;
	#my $url = HTTP::Request->new(GET => 'http://www.smn.gov.ar/?mod=dpd&id=25');
	#my $url = HTTP::Request->new(GET => 'http://weather.yahooapis.com/forecastrss?p=ARBA1809&u=c');
	my $url = HTTP::Request->new(GET => 'http://www.smn.gov.ar/layouts/temperatura_layout.php');


	my $ua = new LWP::UserAgent;
	$ua->agent('Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/533.4 (KHTML, like Gecko) Chrome/5.0.375.70 Safari/533.4'); #overkill? 
#	$ua->protocols_allowed( [ 'http', 'https'] );
	$ua->max_redirect( 2 );
	$ua->timeout( 20 );

	my $req = $ua->request( $url );
	if ($req->decoded_content) {
		my $temp = $req->decoded_content;
		$temp =~ s/\|TRUE//;
		$server->command("MSG $chan $temp");
		return;

	} else {
		#no success
		print_msg("FAIL!");
	}
}
sub print_msg { Irssi::active_win()->print("@_"); }
signal_add("message public","msg_pub");

