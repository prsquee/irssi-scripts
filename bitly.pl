#shorturl
#
use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use strict;
use WWW::Shorten::Bitly;

sub msg_pub {
  my($server, $text, $nick, $mask,$chan) = @_;
  shortme($text, $chan, $server) if ($server->{tag} =~ /3dg|fnode|lia|gsg/ and $text =~ /^!bitly/);
}

sub shortme {
  my ($text, $chan, $server) = @_;
  my ($url) = $text =~ m{^!bitly (https?://\w+.*)$};
  if (!$url) {
    $server->command("MSG $chan dame un http://sarasa.com and ill bit.ly that for ya");
    return;
  } 
  my $apikey = Irssi::settings_get_str('bitly_apikey'); 
  my $bitly = WWW::Shorten::Bitly->new(URL => $url, USER => "prsquee", APIKEY => $apikey );
  my $shorten = $bitly->shorten(URL => $url);

  if ($shorten) {
         $server->command("MSG $chan shorten: $shorten");
        } 
}
sub print_msg { active_win()->print("@_"); }
signal_add("message public","msg_pub");
Irssi::settings_add_str('bitly', 'bitly_apikey', '');


