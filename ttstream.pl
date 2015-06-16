#stream @sysarmy to #sysarmy
use Irssi qw(server_find_chatnet signal_emit signal_add print settings_add_str settings_get_str settings_set_str ) ;
use strict;
use warnings;
use AnyEvent::Twitter::Stream;
use Data::Dumper;
use HTML::Entities;

#mapping ids to channels
my %channel_for = (
   '57440969'   => '#sysarmy',    #@sysarmy
   '2179429297' => '#sysarmy',    #@nerdear
   '2920961379' => '#sysarmy',    #@chownealo
   '324991882'  => '#ssqquuee',   #@sqbot
   '2920961379' => '#ekoparty',   #@ekoparty
);

my $sysarmy   = '57440969';
my $nerdear   = '2179429297';
my $sqbot     = '324991882';
my $chownealo = '2920961379';
my $ekoparty  = '2920961379';
#
my $twt_content = undef;
my $bold  = '\x02';

my $server = server_find_chatnet("fnode");

our $sysarmyStreamer = undef;

#{{{ show this
sub show_tweet {
  my $tweet = shift;
  #ignore @ replies
  unless (defined($tweet->{in_reply_to_screen_name})) {
    #check if it's a RT, then get the untrunked text
    if (defined($tweet->{retweeted_status})) {
      $twt_content = "[\x02\@$tweet->{user}{screen_name}\x02] "
                   . "RT \@$tweet->{retweeted_status}{user}{screen_name}: "
                   . decode_entities($tweet->{retweeted_status}{text})
                   ;
    }
    else {
      $twt_content = "[\x02\@$tweet->{user}{screen_name}\x02] "
                   . decode_entities($tweet->{text})
                   ;
    }

    #check who is the user and send it to the proper channel.
    if (defined($twt_content)) {
      my $id = $tweet->{user}{id_str};

      $twt_content =~ s/\n|\r/ /g;

      if (exists $channel_for{$id}) {
        sayit($server, $channel_for{$id}, $twt_content);
      }
    }
  }
}
#}}}
#{{{ restart stream
sub restart_stream {
  $sysarmyStreamer = undef;
  print (CRAP "sysarmy stream stopped. sleeping for a while");
  sleep 35;
  start_stream();
}
#}}}

sub start_stream {
  $sysarmyStreamer = AnyEvent::Twitter::Stream->new(
    consumer_key    => settings_get_str('twitter_apikey'),
    consumer_secret => settings_get_str('twitter_secret'),
    token           => settings_get_str('twitter_access_token'),
    token_secret    => settings_get_str('twitter_access_token_secret'),
    method          => "filter",
    follow          => join(',', keys %channel_for),
    on_connect      => sub { print (CRAP "connected to twitter stream.");},
    on_tweet        => \&show_tweet,
#    on_eof          => sub { print (CRAP "EOF: $_[0]"); },
    on_eof          => \&restart_stream,
#    on_error        => sub { print (CRAP "error: $_[0]"); },
    on_error        => \&restart_stream,
    #on_keepalive   => sub { print (CRAP 'still alive');},
    on_delete       => sub { print (CRAP 'a tweet was deleted. so sad');},
    timeout         => 100,
  );
}

sub sayit { my $s = shift; $s->command("MSG @_"); }

#initialize stream on start
start_stream();

