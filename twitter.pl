#twitter
#  http://search.cpan.org/~mmims/Net-Twitter-Lite-0.11002/lib/Net/Twitter/Lite.pm

use Irssi qw(
  signal_emit signal_add
  print
  settings_add_str settings_get_str settings_set_str
);
use strict;
use warnings;
use Net::Twitter::Lite::WithAPIv1_1;
use Net::OAuth;
use HTML::Entities qw(decode_entities);
use Data::Dumper;
use Date::Parse qw(str2time); #thank godess for this black magic

#init
settings_add_str('twitter', 'twitter_apikey',               '');
settings_add_str('twitter', 'twitter_secret',               '');
settings_add_str('twitter', 'twitter_access_token',         '');
settings_add_str('twitter', 'twitter_access_token_secret',  '');
settings_add_str('twitter', 'sysarmy_access_token',         '');
settings_add_str('twitter', 'sysarmy_access_token_secret',  '');

signal_add("fetch tweet",     "do_twitter");
signal_add("last tweet",      "do_last");
signal_add("teh fuck is who", "userbio");
signal_add("white rabbit",    "follow");
signal_add("shit I say",      "tweet_myself");

my $twitter_ref = new_twitter();

sub tweet_myself {
  my ($server, $chan, $send_this) = @_;
  my $return_status = $twitter_ref->update($send_this);
  if ($return_status->{'id'} > 0) {
    sayit($server, $chan, 'tweet sent.');
  }
}

sub follow {
  my ($server, $chan, $new_friend) = @_;
  if ($twitter_ref->create_friend({screen_name => $new_friend})->{'screen_name'} eq $new_friend) {
    sayit ($server, $chan, 'followed.');
  }
}
#{{{ update twitter
sub update {
  my $text = shift;
  eval { $twitter_ref->update($text) };
  print (CRAP "$@") if $@;
}#}}}
#{{{ fetch last tweet
sub do_last {
  my ($server, $chan, $user) = @_;
  if ($user) {
    eval {
      my $results = $twitter_ref->show_user({screen_name => $user});   #needed since v1.1
      #print CRAP Dumper($results);
      if ($results->{status}{created_at}) {
        my $delta = moment_ago($results->{status}{created_at});
        my $lasttweet = "\@$user tweeted: " . '"' . decode_entities($results->{status}{text}) . '" ';
        $lasttweet .= 'from ' . $delta if ($delta);
        sayit($server, $chan, $lasttweet) if ($results->{status}{text});
      }
      else {
        sayit($server, $chan, "I see no tweets.");
      }
    };
    sayit($server, $chan, "$@") if $@;
    #print (CRAP $@);
  }
}
#}}}
#{{{ fuzzy time diff
sub moment_ago {
  #time is always in utc and in secs
  my $created_at = shift;
  $created_at =~ s| \+\d{4}||g;

  my $converted_time = str2time($created_at);
  # -0300 #my server's timezone
  $converted_time -= 10800;

  my $delta = time - $converted_time;
  return undef unless $delta;

  my $ago = undef;

  if ($delta > 2628000) {
    my $mon = int($delta/2592000);
    $ago = $mon <= 1  ? 'about a month ago.'
         : $mon <= 3  ? 'a couple of months ago.'
         : $mon <= 7  ? 'half a year ago.'
         : $mon <= 13 ? 'almost a year ago.'
         : $mon <= 18 ? 'more than a year ago.'
         : $mon <= 25 ? 'almost 2 years ago.'
         : $mon >  26 ? 'more than 2 years ago.'
         : undef;
  }
  elsif ($delta > 86400) {
    my $day = int($delta/86400);
    $ago = $day <= 1  ? 'today.'
         : $day <= 7  ? 'this week.'
         : $day <= 21 ? 'a couple of weeks ago.'
         : $day <= 32 ? 'about a month ago.'
         : undef;
  }
  elsif ($delta > 3600) {
    my $hour = int($delta/3600);
    $ago = $hour <= 1  ? 'about an hour ago.'
         : $hour <= 5  ? 'a couple of hours ago.'
         : $hour <= 24 ? 'less than a day ago.'
         : undef;
  }
  elsif ($delta >= 1) {
    my $min = int($delta/3600);
    $ago = $min <= 29 ? 'just now.'
         : $min <= 60 ? 'less than a hour ago.'
         : undef;
  }
  return defined($ago) ? $ago : undef;
}#}}}
#{{{ user info
sub userbio {
  my ($server,$chan,$who) = @_;
  if ($who) {
    eval {
      my $r = $twitter_ref->show_user({screen_name => $who});
      my $user = "[\@$who] " . "Name: " . $r->{name};
      $user .= " - " . "Bio: " . $r->{description} if ($r->{description});
      $user .= " - " . "Location: " . $r->{location} if ($r->{location});
      my ($year) = $r->{created_at} =~ /(2\d{3})$/;
      $user .= " - " . "User since $year" if ($year);
      my $userstats = 'Tweets: '
                    . $r->{statuses_count}
                    . ' -  Followers: '
                    . $r->{followers_count}
                    . ' -  Following: '
                    . $r->{friends_count}
                    ;
      sayit($server, $chan, $user);
      sayit($server, $chan, $userstats);
    };
    print (CRAP $@) if $@;
  }
}
#}}}
#{{{ search twt
#sub do_search {
#  
#  my ($text, $chan, $server) = @_;
#  if ($text =~ /^!searchtwt$/) {
#    sayit($server,$chan,"i will search anything on twittersphere!");
#  }
#  else {
#    my ($query) = $text =~ /^!searchtwt (.*)/i;
#    if ($query) {
#      eval {
#        my $r = $twitter_ref->search($query);
#        for (0..9) {
#          #for (all) my $status ( @${$r->{results}}) {
#          for my $status ( ${$r->{results}}[$_]) {
#            #my $a = Dumper($status);
#            #print_msg("$a");
#            return if (!$status);
#            my $tweet = decode_entities($status->{text});
#            my $msg = "\@" . $status->{from_user} . ": " . $tweet;
#            sayit($server, $chan, $msg);
#          }
#        }
#      };
#      return if $@;
#    }
#  }
#}
#}}}
#{{{ do twitter
sub do_twitter {
  my ($server, $chan, $text) = @_;
  my ($user, $status_id)
    = $text
      =~ m{twitter\.com(?:/\#!)?/([^/]+)/status(?:es)?/(\d+)}i;

  my $status = eval { $twitter_ref->show_status($status_id) };
  return if $@;

  my $delta = moment_ago($status->{created_at});

  my $result = "\@${user} "
             . 'tweeted: '
             . '"'
             . decode_entities($status->{text})
             . '"'
             ;

  $result =~ s/\n|\r/ /g;
  $result .= $delta ? ' from ' . $delta : '';

  #replace all the t.co urls
  if (ref $status->{'entities'}->{'urls'} eq 'ARRAY') {
    foreach my $link (@{ $status->{'entities'}->{'urls'} }) {
      my $expanded_url = $link->{'expanded_url'};
      $expanded_url =~ s/(?:\?|&)utm_\w+=\w+//g;
      $result =~ s/($link->{'url'})/$expanded_url/;
    }
  }

  if (ref $status->{'entities'}->{'media'} eq 'ARRAY') {
    foreach my $link (@{ $status->{'entities'}->{'media'} }) {
      my $expanded_url = $link->{'expanded_url'};
      $result =~ s/($link->{'url'})/$expanded_url/;
    }
  }

  #$result .= $status->{'in_reply_to_screen_name'} ? ' In reply to @' . $status->{'in_reply_to_screen_name'} : '';

  sayit($server, $chan, $result) if ($result);
}
#}}}
#{{{ new twtrr
sub new_twitter {
  my %consumer_tokens = (
  consumer_key    => settings_get_str('twitter_apikey'),
  consumer_secret => settings_get_str('twitter_secret'),
  );
  my $twitter;
  if (%consumer_tokens) {
    $twitter = Net::Twitter::Lite::WithAPIv1_1->new(
      %consumer_tokens,
      legacy_lists_api  =>  0,
      ssl               =>  1,
    );
  } else {
    print (CRAP "no keys!");
    return;
  }
  #my ($at, $ats) = restore_tokens(); #this seems like forever
  my $at  = settings_get_str('twitter_access_token');
  my $ats = settings_get_str('twitter_access_token_secret');
  if ($at && $ats) {
    $twitter->access_token($at);
    $twitter->access_token_secret($ats);
  } else {
    print (CRAP "no tokens!");
    return;
  }
  return $twitter;
}
#}}}
#{{{ signals and stuff
sub sayit { my $s = shift; $s->command("MSG @_"); }
#}}}
sub is_loaded { return exists($Irssi::Script::{shift(@_).'::'}); }
