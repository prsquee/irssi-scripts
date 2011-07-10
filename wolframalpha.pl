use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use strict;
use WWW::WolframAlpha;

sub msg_pub {
	my($server, $text, $nick, $mask,$chan) = @_;
	do_query($text, $chan, $server) if ($server->{tag} =~ /3dg|fnode|lia|gsg/ and $text =~ /^!wa/);
}

sub do_query {
	my ($text, $chan, $server) = @_;
	my ($input) = $text =~ /^!wa (.*)$/;
	if ($input) {
		my $appid = Irssi::settings_get_str('wa_appid');

		my $wa = WWW::WolframAlpha->new ( appid => $appid );
		my $query = $wa->query (
			input => $input,

		);
		if ($query->success) {
			print_msg($query->numpods);
		} 
	}
	else {
		$server->command("MSG $chan I wish I'm WolframAlpha, I can ask her anything tho");
	}

#	if ($server) {
#	       $server->command("MSG $chan some reply");
#       } 
}
sub print_msg { active_win()->print("@_"); }
signal_add("message public","msg_pub");
Irssi::settings_add_str('wolfram', 'wa_appid', '');

