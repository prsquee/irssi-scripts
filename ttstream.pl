#stream @sysarmy to #sysarmy
use Irssi qw(server_find_chatnet signal_emit signal_add print settings_add_str settings_get_str settings_set_str ) ;
use strict;
use warnings;
use AnyEvent::Twitter::Stream;
use Data::Dumper;
use HTML::Entities;

my $sysarmy   = '57440969';
my $nerdear   = '2179429297';
my $sqbot     = '324991882';
my $chownealo = '2920961379';
#my $prsquee = '31968735';
#
my $chan  = '#ssqquuee';
my $out   = undef;
my $bold  = '\x02';

my $server = server_find_chatnet("fnode");

our $sysarmyStreamer = undef;

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
      if ($tweet->{user}{id_str} eq $sqbot) {
        $server->command("MSG #ssqquuee $out");
      }
      elsif ($tweet->{user}{id_str} =~ /$sysarmy|$nerdear|$chownealo/) {
        $server->command("MSG #sysarmy $out");
      }
    }
  }
  #$server->command("MSG $chan [\x02\@$tweet->{user}{screen_name}\x02] $tweet->{text}") 
}

sub restart_stream {
  $sysarmyStreamer = undef;
  print (CRAP "sysarmy stream stopped. sleeping for a while");
  sleep 35;
  start_stream();
}

sub start_stream {
  $sysarmyStreamer = AnyEvent::Twitter::Stream->new(
    consumer_key    => settings_get_str('twitter_apikey'),
    consumer_secret => settings_get_str('twitter_secret'),
    token           => settings_get_str('twitter_access_token'),
    token_secret    => settings_get_str('twitter_access_token_secret'),
    method          => "filter",
    follow          => "$sysarmy, $nerdear, $chownealo, $sqbot",
    on_connect      => sub { print (CRAP "connected to sysarmy stream.");},
    on_tweet        => \&show_tweet,
#    on_eof          => sub { print (CRAP "EOF: $_[0]"); },
    on_eof          => \&restart_stream,
#    on_error        => sub { print (CRAP "error: $_[0]"); },
    on_error        => \&restart_stream,
    #on_keepalive   => sub { print (CRAP 'still alive');},
    on_delete       => sub { print (CRAP 'a tweet was deleted. so sad');},
    timeout         => 700,
  );
}

start_stream();
