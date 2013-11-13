#send @sysarmy to #sysarmy
use Irssi qw(server_find_chatnet signal_emit signal_add print settings_add_str settings_get_str settings_set_str ) ;
use strict;
use warnings;
use AnyEvent::Twitter::Stream;
use Data::Dumper;
use HTML::Entities;

my $sysarmy = '57440969';
my $sqbot   = '324991882';
#my $prsquee = '31968735';
my $chan = '#ssqquuee';
my $out = undef;

my $server = server_find_chatnet("fnode");
sub show_tweet {
  my $tweet = shift;
  #not interested in @replies.
  unless (defined($tweet->{in_reply_to_screen_name})) {
    #check if it's a RT, then get the untrunked text
    if (defined($tweet->{retweeted_status})) {
      $out = "[\x02\@$tweet->{user}{screen_name}\x02] ";
      $out .= "RT \@$tweet->{retweeted_status}{user}{screen_name}: ";
      $out .= decode_entities($tweet->{retweeted_status}{text});
    } 
    else { 
      $out = "[\x02\@$tweet->{user}{screen_name}\x02] " . decode_entities($tweet->{text});
    }
    if (defined($out)) {
      $out =~ s/\n|\r/ /g;
      $server->command("MSG #ssqquuee $out")  if ($tweet->{user}{id_str} eq $sqbot);
      $server->command("MSG #sysarmy $out")   if ($tweet->{user}{id_str} eq $sysarmy);
    }
  }
  #$server->command("MSG $chan [\x02\@$tweet->{user}{screen_name}\x02] $tweet->{text}") 
}
our $sysarmyStream = AnyEvent::Twitter::Stream->new(
  consumer_key    => settings_get_str('twitter_apikey'),
  consumer_secret => settings_get_str('twitter_secret'),
  token           => settings_get_str('twitter_access_token'),
  token_secret    => settings_get_str('twitter_access_token_secret'),
  method          => "filter",
  follow          => "$sysarmy, $sqbot",
  on_connect      => sub { print (CRAP "connected to twitter stream.");},
  on_tweet        => \&show_tweet,
  on_eof          => sub { print (CRAP "EOF.") && return;},
  on_error        => sub { print (CRAP "$_[0];") and return ;},
  #on_keepalive    => sub { print (CRAP "still alive");},
  on_delete       => sub { print (CRAP "a tweet was deleted. so sad");},
  timeout         => 100,
);
