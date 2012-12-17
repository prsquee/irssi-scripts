#check youtube title and desc

use Irssi qw (signal_add print settings_get_str );
use warnings;
use strict;
use IO::Socket::INET; #TODO this is so ugly, I need to use json asap
use Data::Dumper;
use LWP::UserAgent;
use JSON;

#init 
my $json = new JSON;
my $ua = new LWP::UserAgent;
$ua->timeout(10);
$ua->agent(settings_get_str('myUserAgent'));

sub fetch_tubes {
	my($server,$chan,$vid) = @_;
  my $url = "http://gdata.youtube.com/feeds/api/videos/$vid?&v=2&alt=json";
  my $req = $ua->get($url);
  my $result = $json->utf8->decode($req->decoded_content)->{entry};
  #print (CRAP Dumper($decoded_json));
  my $title  = $result->{title}->{'$t'};
  my $desc   = $result->{'media$group'}->{'media$description'}->{'$t'};
  my $time   = $result->{'media$group'}->{'yt$duration'}->{seconds};
  my $views  = $result->{'yt$statistics'}->{'viewCount'};

  #my ($title, $desc, $time, $views) = get_title($vid) if ($vid);
  if($title) {
    if ($time < 10) {
      $time = "[0:0${time}]";
    } elsif ($time < 60) {
        $time = "[0:${time}]";
    } elsif ($time >= 60) {
          use integer;
          my $min = $time / 60;
          my $sec = $time % 60;
          $sec = "0" . $sec if ($sec < 10);
          $time = "[${min}:${sec}]";
    }
    my $msg = "[YT]" . $time . " - " . "\x02${title}\x02";
    $msg .= " - $desc" if ($desc); 
    $msg .= " - Views: $views" if ($views);
    sayit($server, $chan, $msg);
  } else { return; }
}

sub sayit {
	my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}
signal_add("check tubes", "fetch_tubes"); 
