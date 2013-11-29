#twitter
#http://search.cpan.org/~mmims/Net-Twitter-Lite-0.11002/lib/Net/Twitter/Lite.pm 

use Irssi qw(signal_emit signal_add print settings_add_str settings_get_str settings_set_str ) ;
use strict;
use warnings;
use Net::Twitter::Lite::WithAPIv1_1 0.12004;
use HTML::Entities;
use Data::Dumper;
use Date::Parse qw(str2time); #thank godess for this black magic

#init 
signal_add("fetch tweet",     "do_twitter");
signal_add("last tweet",      "do_last");
signal_add("teh fuck is who", "userbio");
signal_add("post twitter",    "update");

#settings_add_str('twitter', 'twitter_apikey',               '');
#settings_add_str('twitter', 'twitter_secret',               '');
#settings_add_str('twitter', 'twitter_access_token',         '');
#settings_add_str('twitter', 'twitter_access_token_secret',  '');
#settings_add_str('twitter', 'sysarmy_access_token',         '');
#settings_add_str('twitter', 'sysarmy_access_token_secret',  '');


my $twitterObj  = newtwitter();

#do a polling of new tweets or stream?
#
#{{{ update twitter 
sub update {
  my $text = shift;
  eval { $twitterObj->update($text) };
  print (CRAP "$@") if $@;
}#}}}
#{{{ fetch last tweet
sub do_last {
  my ($server,$chan,$user) = @_;
  if ($user) {
    eval {
      my $r = $twitterObj->show_user({screen_name => $user});   #changed since v1.1 need to pass screen_name or user_id directly
      my $delta = moment_ago($r->{status}{created_at});
      my $lasttweet = "\@$user tweeted: " . '"' . decode_entities($r->{status}{text}) . '" ';
      $lasttweet .= 'from ' . $delta . ' ago' if ($delta);
      sayit($server,$chan,$lasttweet) if ($r->{status}{text});
    };
    print (CRAP $@) if $@;
  }
}
#}}}
#{{{ time diff 
sub moment_ago {
  #my ($time,$offset) = @_;
  my ($time) = @_;
  #time is always in utc and in secs
  $time =~ s| \+\d{4}||g;
  my $t = str2time($time);
  $t -= 10800; #-0300 #server's tz

  my $diff  = time - $t;
  return undef unless $diff;

  if ($diff > 31536000) {
    my $y = sprintf("%d" ,$diff/31536000);
    $y > 1 ? return "$y years" : return "a year";
  } elsif ($diff > 2592000) {
      my $m = sprintf("%d", $diff/2592000);
      $m > 1 ? return "$m months" : return "a month";
    } elsif ($diff > 86400) {
        my $d = sprintf("%d" ,$diff/86400);
        $d > 1 ? return "$d days" : return "a day";
      } elsif ($diff > 3600) {
          my $h = sprintf("%d" ,$diff/3600);
          $h > 1 ? return "$h hours" : return "an hour";
        } elsif ($diff >= 60) {
            my $m = sprintf("%d" ,$diff/60);
            $m > 1 ? return "$m mins" : return "just a minute";
          } return "$diff secs" if ($diff < 60 and $diff > 0);
  return undef if ($diff <= 0);  #fucked up time zones 
}#}}}
#{{{ user info
sub userbio {
  my ($server,$chan,$who) = @_;
  if ($who) {
    eval {
      my $r = $twitterObj->show_user({screen_name => $who});
      my $user = "[\@$who] " . "Name: " . $r->{name};
      $user .= " - " . "Bio: " . $r->{description} if ($r->{description}); 
      $user .= " - " . "Location: " . $r->{location} if ($r->{location});
      my ($year) = $r->{created_at} =~ /(2\d{3})$/;
      $user .= " - " . "User since $year" if ($year);
      my $userstats = "Tweets: " . $r->{statuses_count} . " - ". "Followers: " . $r->{followers_count} . " - " . "Following: " . $r->{friends_count};
      sayit($server,$chan,$user);
      sayit($server,$chan,$userstats);
    };
    print (CRAP $@) if $@;
  }
}
#}}}
#{{{ search twt
sub do_search {
  my ($text, $chan, $server) = @_;
  if ($text =~ /^!searchtwt$/) {
    sayit($server,$chan,"i will search anything on twittersphere!");
  } else {
    my ($query) = $text =~ /^!searchtwt (.*)/i;
    if ($query) {
      #my $twitter = newtwitter();
      eval {
        my $r = $twitterObj->search($query);
        for (0..9) {
          #for (all) my $status ( @${$r->{results}}) {
          for my $status ( ${$r->{results}}[$_]) {
            #my $a = Dumper($status);
            #print_msg("$a");
            return if (!$status); 
            my $tweet = decode_entities($status->{text});
            my $msg = "\@" . $status->{from_user} . ": " . $tweet;
            sayit($server, $chan, $msg);
          }
        }
      };
      return if $@;
    }
  }
}
#}}}
#{{{ do twitter
sub do_twitter {
  my ($server,$chan,$text) = @_;
  my ($user,$statusid) = $text =~ m{twitter\.com(?:/\#!)?/([^/]+)/status(?:es)?/(\d+)}i; 
  my $status = eval { $twitterObj->show_status($statusid) };
  return if $@;

  my $delta = moment_ago($status->{created_at});
  my $result = "\@${user} " . 'tweeted: '. '"'. decode_entities($status->{text}) . '" ';
  $result .= 'from ' . $delta . ' ago' if ($delta);

  my $replyurl = "http://twitter.com/" . $user . "/status/" . $status->{in_reply_to_status_id} if ($status->{in_reply_to_status_id});
  my $shorturl = scalar('Irssi::Script::ggl')->can('do_shortme')->($replyurl) if ($replyurl);

  $result .= ". in reply to " . $shorturl if ($shorturl);
  sayit($server,$chan,$result) if ($result);
  #signal_emit('write to file', "$result\n") if ($result and $chan =~ /sysarmy|moob/);
}
#}}}
#{{{ new twtrr 
sub newtwitter {
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
sub sayit {
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}
#}}}
