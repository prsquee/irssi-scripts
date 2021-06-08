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
use v5.32;

#mapping ids to channels
my %channel_for = (
   '57440969'   => '#sysarmy',    #@sysarmy
   '2179429297' => '#sysarmy',    #@nerdear
   '324991882'  => '#ssqquuee',   #@sqbot
);

#track this

my $server = server_find_chatnet("libera");
our $sysarmyStreamer = undef;

#{{{ show this
sub show_tweet {
  my $tweet = shift;
  my $output = undef;

  #ignore @ replies
  unless (defined($tweet->{in_reply_to_screen_name})) {
    #check if it's a RT, then get the untrunked text
    if ($tweet->{retweeted_status}) {
      $output = "[\@$tweet->{user}{screen_name}] "
                   . "retweeted: \"\@$tweet->{retweeted_status}{user}{screen_name}: "
                   . decode_entities(
                      $tweet->{retweeted_status}->{'truncated'}
                      ? $tweet->{retweeted_status}{extended_tweet}{full_text}
                      : $tweet->{retweeted_status}{text}
                     ) . '"';
    }
    elsif ($tweet->{is_quote_status}) {
    # original quoted tweet
      $output = "[\@$tweet->{user}{screen_name}] \"<\@$tweet->{quoted_status}{user}{screen_name}> "
              . decode_entities(
                  $tweet->{quoted_status}->{'truncated'}
                  ? $tweet->{quoted_status}{extended_tweet}{full_text}
                  : $tweet->{quoted_status}{text}
                ) . '"';
    # our added text
      $output .=  ' << '
              . decode_entities(
                  $tweet->{truncated}
                  ? $tweet->{extended_tweet}{full_text}
                  : $tweet->{text}
                );
    }
    else {
      $output = "[\@$tweet->{user}{screen_name}] "
              . decode_entities(
                  $tweet->{truncated}
                  ? $tweet->{extended_tweet}{full_text}
                  : $tweet->{text}
                );
    }

    #replace all the t.co urls
    if (ref $tweet->{'entities'}->{'urls'} eq 'ARRAY') {
      if (scalar @{ $tweet->{'entities'}->{'urls'}} > 0 ) {
        foreach my $link (@{ $tweet->{'entities'}->{'urls'} }) {
          my $expanded_url = $link->{'expanded_url'} || undef;
          if ($expanded_url) {
            $expanded_url =~ s/(?:\?|&)utm_\w+=\w+//g;
            $output  =~ s/($link->{'url'})/$expanded_url/;
          }
        }
      }
    }

    if (ref $tweet->{'entities'}->{'media'} eq 'ARRAY') {
      foreach my $link (@{ $tweet->{'entities'}->{'media'} }) {
        my $media_url = $link->{'media_url'};
        $output =~ s/($link->{'url'})/$media_url/;
      }
    }

    #check who is the user and send it to the proper channel.
    if (defined($output)) {
      my $id = $tweet->{user}{id_str};
      $output =~ s/\n|\r/ /g;
      if (exists $channel_for{$id}) {
        sayit($server, $channel_for{$id}, $output);
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
    on_connect      => sub { print (CRAP 'connected to twitter stream.');},
    on_tweet        => \&show_tweet,
    on_eof          => \&restart_stream,
    on_error        => \&restart_stream,
    #on_keepalive   => sub { print (CRAP 'still alive');},
    #on_delete       => sub { print (CRAP 'a tweet was deleted. so sad');},
    timeout         => 50,
  );
}

sub sayit { my $s = shift; $s->command("MSG @_"); }

#initialize stream on start
start_stream();

