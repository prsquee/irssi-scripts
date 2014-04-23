#twitter
#  http://search.cpan.org/~mmims/Net-Twitter-Lite-0.11002/lib/Net/Twitter/Lite.pm

use Irssi qw(signal_emit signal_add print settings_add_str settings_get_str settings_set_str ) ;
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
signal_add("post twitter",    "update");

my $twitter_ref = new_twitter();

#do a polling of new tweets or stream?
#
#{{{ update twitter 
sub update {
  my $text = shift;
  eval { $twitter_ref->update($text) };
  print (CRAP "$@") if $@;
}#}}}
#{{{ fetch last tweet
sub do_last {
  my ($server,$chan,$user) = @_;
  if ($user) {
    eval {
      my $results = $twitter_ref->show_user( { screen_name => $user } );   #needed since v1.1
      #print CRAP Dumper($results);
      if ($results->{status}{created_at}) {
        my $delta = moment_ago($results->{status}{created_at});
        my $lasttweet = "\@$user tweeted: " . '"' . decode_entities($results->{status}{text}) . '" ';
        $lasttweet .= 'from ' . $delta . ' ago' if ($delta);
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
#{{{ time diff 
sub moment_ago {
  #time is always in utc and in secs
  my $created_at = shift;
  $created_at =~ s| \+\d{4}||g;

  my $converted_time = str2time($created_at);
  $converted_time -= 10800;       # -0300 #my server's timezone

  my $delta  = time - $converted_time;
  return undef unless $delta;

  if ($delta > 31536000) {
    my $y = sprintf("%d" ,$delta/31536000);
    $y > 1 ? return "$y years" : return "a year";
  }
  elsif ($delta > 2592000) {
      my $m = sprintf("%d", $delta/2592000);
      $m > 1 ? return "$m months" : return "a month";
    }
    elsif ($delta > 86400) {
        my $d = sprintf("%d" ,$delta/86400);
        $d > 1 ? return "$d days" : return "a day";
      }
      elsif ($delta > 3600) {
          my $h = sprintf("%d" ,$delta/3600);
          $h > 1 ? return "$h hours" : return "an hour";
        }
        elsif ($delta >= 60) {
            my $m = sprintf("%d" ,$delta/60);
            $m > 1 ? return "$m mins" : return "just a minute";
        }
  return "$delta secs" if ($delta < 60 and $delta > 0);
  return undef if ($delta <= 0);  #some fucked up time zones 
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
      #my $twitter = new_twitter();
      eval {
        my $r = $twitter_ref->search($query);
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
  my $status = eval { $twitter_ref->show_status($statusid) };
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
