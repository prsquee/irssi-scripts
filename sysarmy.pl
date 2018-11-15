#sysARmy
#http://search.cpan.org/~mmims/Net-Twitter-Lite-0.10004/lib/Net/Twitter/Lite.pm

use Irssi qw(signal_add print settings_add_str settings_get_str settings_set_str ) ;
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
sub send_to_twitter {
  my $tweet_this = shift;
  my $status = undef;

  eval { $status = $twitter->update(decode('utf8', $tweet_this)) };

  if (!$@) {
    #print (CRAP $status->{id});
    return 'tweeted';
  }
  else {
    #my $err = $@;
    print (CRAP $@);
    return undef;
  }
}

sub sayit { my $s = shift; $s->command("MSG @_"); }
