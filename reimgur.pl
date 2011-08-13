#reupload an img to imgur
#
#
#
use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use strict;
use WWW::Imgur; 
use JSON;
#use Data::Dumper;

sub msg_pub {
	my($server, $text, $nick, $mask,$chan) = @_;
	if ($server->{tag} =~ /3dg|fnode|lia|gsg/) {
			my ($url) = $text =~ m{^!imgur (https?://[^ ]+)};
			if ($text =~ /^!imgur/ and not $url) {
				sayit($server,$chan,"dame un link a una imagen y lo reuploadeo a imgur!");
			}
			reupload($url,$server,$chan) if ($url);
	}
}

sub reupload {
	my ($url,$server,$chan) = @_;
	my $imgur = WWW::Imgur->new ();
	my $apikey = Irssi::settings_get_str('imgurkey');
        $imgur->key ($apikey);
	my $jsreply = $imgur->upload($url) or (sayit($server,$chan,"Upload failed") and return);
	if ($jsreply) {
		my $json = new JSON;
		my $reply = $json->allow_nonref->decode($jsreply);
		#print_msg(Dumper($reply));
		my $link = $reply->{'upload'}->{'links'}->{'original'};
		sayit($server,$chan,$link) if ($link);
	}
}
sub sayit { 
	my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}                                         
sub print_msg { active_win()->print("@_"); }
signal_add("message public","msg_pub");
Irssi::settings_add_str('imgur','imgurkey','');
