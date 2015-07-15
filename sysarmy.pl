#sysARmy
#http://search.cpan.org/~mmims/Net-Twitter-Lite-0.10004/lib/Net/Twitter/Lite.pm

use Irssi qw(signal_add print settings_add_str settings_get_str settings_set_str ) ;
use Scalar::Util 'blessed';
use strict;
use warnings;
use Net::Twitter::Lite::WithAPIv1_1;
use Net::OAuth;
use Data::Dumper;
use Encode qw (encode decode);

#{{{ #init 
settings_add_str('twitter', 'twitter_apikey',              '');
settings_add_str('twitter', 'twitter_secret',              '');
settings_add_str('twitter', 'sysarmy_access_token',        '');
settings_add_str('twitter', 'sysarmy_access_token_secret', '');
signal_add("post sysarmy",  "post_twitter");


my %consumer_tokens = (
  consumer_key    => settings_get_str('twitter_apikey'),
  consumer_secret => settings_get_str('twitter_secret'),
);
my $twitter;
if (%consumer_tokens) {
  $twitter = Net::Twitter::Lite::WithAPIv1_1->new(
    %consumer_tokens,
    ssl => 1,
  );
} 
else {
  print (CRAP "no keys!");
  return;
}

my $at  = settings_get_str('sysarmy_access_token');
my $ats = settings_get_str('sysarmy_access_token_secret');

if ($at && $ats) {
  $twitter->access_token($at);
  $twitter->access_token_secret($ats);
} 
else {
  print (CRAP "I cant hold all these non existen token in my hands!");
  return;
}
#print (CRAP Dumper($army));
#}}} 
#{{{ post to twitter and return a short url
#TODO refacor this.
sub send_to_twitter {
  my $tweet_this = shift;
  my $status = undef;

  eval { $status = $twitter->update(decode('utf8', $tweet_this)) };
 
  if (!$@) {
    #get the link to the tweet we just sent.
    #shorten that
    my $shorten 
      = scalar('Irssi::Script::ggl')->can('do_shortme')->(
                                        'https://twitter.com/sysARmIRC/status/' 
                                       . $status->{'id'}
                                     );
    #return that short url
    return $shorten;
  } 
  else {
    #my $err = $@;
    print (CRAP $@);
    return undef;
  }
}
#}}}
#{{{ do twitter
#sub post_twitter {
#  my ($server, $chan, $text) = @_;
#  #print (CRAP $text));
#  my $status;
#  eval { $status = $twitter->update(decode('utf8', $text)) };
#  if ($@) {
#    my $err = $@;
#    sayit($server, $chan,"error: $@") unless blessed $err && $err->isa('Net::Twitter::Lite::Error');
#    print (CRAP "HTTP Response Code: ", $err->code);
#    print (CRAP "HTTP Message: ", $err->message);
#    print (CRAP "Twitter error: ", $err->error);
#  } else {
#    #sayit($server,$chan,"*chirp*");
#    my $url = 'https://twitter.com/sysARmIRC/status/' . $status->{id};
#    my $short = scalar('Irssi::Script::ggl')->can('do_shortme')->($url);
#    sayit($server, $chan, "tweet sent at $short") if ($short);
#  }
#  #print (CRAP Dumper($twitter));
#}
#}}}
#{{{ sayit
sub sayit { my $s = shift; $s->command("MSG @_"); }
#}}}
