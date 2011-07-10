use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use strict;
use LWP::UserAgent;
use JSON;
#use WWW::Shorten::Bitly;
use WWW::Shorten::Googl;



sub msg_pub {
	my($server, $text, $nick, $mask,$chan) = @_;
	do_ihq($text, $chan, $server) if ($server->{tag} =~ /3dg|fnode|lia|gsg/ and $text =~ /^!ihq/);
}

sub do_ihq {
	my ($text, $chan, $server) = @_;
	my ($searchme) = $text =~ /^!ihq (\w.*)$/;
	if (!$searchme) {
		$server->command("MSG $chan que busco en isohunt?");
		return;
	} 
	#bold
	$searchme =~ s/\s+/%20/;
	my $query = 'http://isohunt.com/js/json.php?ihq=' . $searchme . '&sort=seeds' . '&rows=6';
	#print_msg("$query");

	my $ua = new LWP::UserAgent;
	$ua->agent('Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/533.4 (KHTML, like Gecko) Chrome/5.0.375.70 Safari/533.4'); #overkill? 
	$ua->timeout( 10 );


	my $got = $ua->get( $query );
	my $content = $got->decoded_content; 
	my $json = new JSON;
	my $json_text = $json->allow_nonref->utf8->relaxed->decode($content);

	foreach my $result ( @{$json_text->{items}->{list}} ) {
		my $title = $result->{title};
		$title =~ s/<\/?b>/\x02/g;  #making it a feature! (?)
		my $torrent = $result->{enclosure_url}; 
		
		my $short = makeashorterlink($torrent);

		my $SL = 'S/L: ' . $result->{Seeds} . '/' . $result->{leechers} ; 
		my $cat = $result->{category};

		$server->command("MSG $chan [isohunt] $title - $SL - $cat - $short");
	}

}
sub print_msg { active_win()->print("@_"); }
signal_add("message public","msg_pub");

