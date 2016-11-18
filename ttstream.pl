#stream twitter to channels
use Irssi qw(
  server_find_chatnet
  signal_emit
  signal_add
  print
  settings_add_str
  settings_get_str
  settings_set_str
  timeout_add_once
);
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
   '15521218'   => '#ekoparty',   #@ekoparty
);

#track this

my @eko_hashtags =  ( '#ekoparty', '#eko11' );

my $twt_content = undef;
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
    #replace all the t.co urls
    if (ref $tweet->{'entities'}->{'urls'} eq 'ARRAY') {
      if (scalar @{ $tweet->{'entities'}->{'urls'}} > 0 ) {
        foreach my $link (@{ $tweet->{'entities'}->{'urls'} }) {
          my $expanded_url = $link->{'expanded_url'};
          $expanded_url =~ s/(?:\?|&)utm_\w+=\w+//g;
          $twt_content =~ s/($link->{'url'})/$expanded_url/;
        }
      }
    }

    if (ref $tweet->{'entities'}->{'media'} eq 'ARRAY') {
      foreach my $link (@{ $tweet->{'entities'}->{'media'} }) {
        my $media_url = $link->{'media_url'};
        $twt_content =~ s/($link->{'url'})/$media_url/;
      }
    }

    #check who is the user and send it to the proper channel.
    if (defined($twt_content)) {
      my $id = $tweet->{user}{id_str};
      $twt_content =~ s/\n|\r/ /g;
      if (exists $channel_for{$id}) {
        sayit($server, $channel_for{$id}, $twt_content);
      }
      else {
        #the uesr id is not found in the channel hash, so this must be from a 
        #keyword we are tracking
        #altho keyboard tracking shouldbe another hash.
        my $eko_keyword_re = join('|', @eko_hashtags);
        if ($twt_content =~ /$eko_keyword_re/) {
          sayit($server, '#ekoparty', $twt_content) 
            unless defined($tweet->{retweeted_status});
        }
      }
    }
  }
}
#}}}
#{{{ restart stream
sub restart_stream {
  $sysarmyStreamer = undef;
  timeout_add_once(45000, 'start_stream', undef);
  print (CRAP "twitter stream stopped. wait for 45 secs to reconnect");
  #do a incremental sleep here.
}
#}}}

sub start_stream {
  $sysarmyStreamer = AnyEvent::Twitter::Stream->new(
    consumer_key    => settings_get_str('twitter_apikey'),
    consumer_secret => settings_get_str('twitter_secret'),
    token           => settings_get_str('twitter_access_token'),
    token_secret    => settings_get_str('twitter_access_token_secret'),
    method          => 'filter',
    follow          => join(',', keys %channel_for),
    track           => join(',', @eko_hashtags),
    on_connect      => sub { print (CRAP 'connected to twitter stream.');},
    on_tweet        => \&show_tweet,
    on_eof          => \&restart_stream,
    on_error        => \&restart_stream,
    #on_keepalive   => sub { print (CRAP 'still alive');},
    on_delete       => sub { print (CRAP 'a tweet was deleted. so sad');},
    timeout         => 100,
  );
}

sub sayit { my $s = shift; $s->command("MSG @_"); }

#initialize stream on start
start_stream();

