#reupload an img to imgur
#this is gonna live until imgur deprecates this old api
#
#
use Irssi qw(signal_add print settings_get_str);
use strict;
use WWW::Imgur;
use JSON;
use Data::Dumper;

signal_add('reimgur','reupload');
my $imgur = WWW::Imgur->new ();
$imgur->key(settings_get_str('imgurkey'));
my $json = new JSON;
sub reupload {
	my ($server,$chan,$url) = @_;
	my $success = $imgur->upload($url) or (sayit($server,$chan,"Upload failed") and return);
	if ($success) {
		my $reply = $json->allow_nonref->utf8->decode($success);
		my $link = $reply->{'upload'}->{'links'}->{'original'};
		sayit($server,$chan,"[IMGUR] $link") if ($link);
	}
}
sub sayit {
	my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}
