use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use WWW::Shorten::Googl;
use strict;

sub msg_pub {
	my($server, $text, $nick, $mask,$chan) = @_;
	do_shortme($text, $chan, $server) if ($server->{tag} =~ /3dg|fnode|lia|gsg/ and $text =~ /^!short/);
}

sub do_shortme {
	my ($text, $chan, $server) = @_;
	my ($url) = $text =~ m{^!short (https?://\w+.*)$};
	if (!$url) {
		$server->command("MSG $chan I need a http://sarasa.com");
		return;
	} 
	my $short_url = makeashorterlink($url);
	if ($short_url) {
	       $server->command("MSG $chan $short_url");
	}
		
}
	
sub print_msg { active_win()->print("@_"); }
signal_add("message public","msg_pub");


