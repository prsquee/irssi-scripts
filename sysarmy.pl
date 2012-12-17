#sysARmy
#http://search.cpan.org/~mmims/Net-Twitter-Lite-0.10004/lib/Net/Twitter/Lite.pm

use Irssi qw(signal_add print settings_add_str settings_get_str settings_set_str ) ;
use strict;
use Net::Twitter::Lite;
use Data::Dumper;
use Encode qw (encode decode);

#{{{ #init 
signal_add("post sysarmy",  "post_twitter");

my %consumer_tokens = (
  consumer_key    => settings_get_str('twitter_apikey'),
  consumer_secret => settings_get_str('twitter_secret'),
);
my $twitter = Net::Twitter::Lite->new(
  %consumer_tokens,
  legacy_lists_api      =>  0,
);

my $at      = settings_get_str('sysarmy_access_token');
my $ats     = settings_get_str('sysarmy_access_token_secret');

if ($at && $ats) {
  $twitter->access_token($at);
  $twitter->access_token_secret($ats);
} else {
  print (CRAP "I cant hold all these non existen token in my hands!");
}
#print (CRAP Dumper($army));
#}}} 
#{{{ quote 2 tweet
sub tweetquote {
  my $text = shift;
  eval { $twitter->update($text) };
  if (!$@) {
    return 1;
  } else {
    print (CRAP $@);
    return undef;
  }
}
#}}}
#{{{ do twitter
sub post_twitter {
	my ($server,$chan,$text) = @_;
  #print (CRAP $text));
  my $status;
  eval { $status = $twitter->update(decode("utf8", $text)) }; #no idea why this works, and who am i to argue with the encodeing gods.
	if ($@) {
    #contar 140 chars? bitch please.
    sayit($server,$chan,"error: $@");
  } else {
    #sayit($server,$chan,"*chirp*");
    my $url = 'https://twitter.com/sysARmIRC/status/' . $status->{id};
    my $short = scalar('Irssi::Script::ggl')->can('do_shortme')->($url);
    sayit($server,$chan,"tweet sent at $short") if ($short);
  }
  #print (CRAP Dumper($twitter));
}
#}}}
#{{{ sayit
sub sayit {
	my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}
#}}}
