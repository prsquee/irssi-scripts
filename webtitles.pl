#webfetchtitle 
use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use LWP::UserAgent;
use strict;


sub msg_pub {
	my($server, $text, $nick, $mask,$chan) = @_;

	my ($urlmatch) = $text =~ m{(https?://[^ ]+)};
#	print_msg("$urlmatch") if ($urlmatch);
	return if ($text =~ /^!\w+/);
	return if ($urlmatch =~ /bolibot/i);
	return if ($urlmatch =~ /(twitter)|(facebook)|(youtu(?:\.be)|be\.com)/i);
	if ($urlmatch =~ /techmez/i) {
		$server->command("MSG $chan Failmez - Lo \"\"último\"\" en ciencia y tecnología");
		return;
	}
			
	do_fetch($text, $chan, $server, $urlmatch) if ($server->{tag} =~ /3dg|fnode|lia|gsg/ and $urlmatch) ;
}

sub do_fetch {
	my ($text, $chan, $server, $urlmatch) = @_;

	my $ua = new LWP::UserAgent;
	$ua->agent('Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/533.4 (KHTML, like Gecko) Chrome/5.0.375.70 Safari/533.4'); #overkill? 
	$ua->protocols_allowed( [ 'http', 'https'] );
	$ua->max_redirect( 3 );
	$ua->timeout( 30 );

	my $response = $ua->head( $urlmatch ); #para ver q es 
	if ($response->is_success) {
		if ($response->content_type) {
			my ($type,$kind) = $response->content_type =~ m{(\w+)/(\w+)};
			my $len = $response->content_length;
			my $kb = int($len/1024) if ($len and $len > 1024);
			#the big case:
			#case 1, ppl didnt like this :<

#			if ($type =~ /image|audio|video|application/ ) {
#				#iwant the pixels!
#				if ($kb) {
#					$server->command("MSG $chan \x02${kind} :: $kb KiB\x20");
#				} else {
#					$server->command("MSG $chan \x02${kind} :: $len bytes\x20") if ($len);
#				}
#				return;
#			}
			#case 2
			if ($response->content_is_html) {
				my $got = $ua->get( $urlmatch );
				my $title = $got->title if ($got->title);
				$server->command("MSG $chan \x02${title}\x20") if ($title); 
				return;
			}
			#case 3
#			if ( $type eq "text" and $kind eq "plain" ) {
#				return;
#				my $got = $ua->get( $urlmatch );
#				my $text = $got->decoded_content if ($got->decoded_content); 
#				my ($line) = $text =~ /^(.*)\r/;
#				#how the fuck do i trim this? nvm 
#				print_msg("$line");
#			}
		}
	} 
}
sub print_msg { Irssi::active_win()->print("@_"); }
signal_add("message public","msg_pub");

