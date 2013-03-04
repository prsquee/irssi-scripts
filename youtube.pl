#check youtube title and desc

use Irssi qw (signal_add signal_emit print settings_get_str );
#use warnings;
use strict;
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
  my $result;
  eval { $result = $json->utf8->decode($req->decoded_content)->{entry} };
  print (CRAP $@) if $@;
  my $title  = $result->{title}->{'$t'};
  my $desc   = $result->{'media$group'}->{'media$description'}->{'$t'};
  my $time   = $result->{'media$group'}->{'yt$duration'}->{seconds};
  my $views  = $result->{'yt$statistics'}->{'viewCount'};

  #my ($title, $desc, $time, $views) = get_title($vid) if ($vid);
  if ($title) {
    if ($time == 0) {
      $time = '[LIVE]';
    } else {
      my $hours = sprintf ("%02d:", $time/3600) if ($time >= 3600);
      $time = $time - 3600 * int($hours) if ($hours);
      my $mins = '00:';
      my $secs;
      if ($time >= 60) {
        $mins = sprintf ("%02d:", $time/60);
        $secs = sprintf ("%02d",  $time%60);
      } elsif ($time < 60) {
        $secs = sprintf("%02d", $time);
      }
      $time = '[time ' . $hours . $mins . $secs . ']';
    }
    my $msg = "[title] ${title} - ${time}";
    #$msg .= " - $desc" if ($desc);
    $msg .= " - [views $views]" if ($views);
    sayit($server, $chan, $msg);
    #save links
    signal_emit('write to file',"[YT] $time - $title - Views: $views\n") if ($chan =~ /sysarmy|moob/);
  } else { return; }
}

#sub search_tubes {
#  #http://gdata.youtube.com/feeds/api/videos?q=funny+cats&alt=json&v=2&prettyprint=trueI#
#  my ($server,$chan,$query) = @_;
#  return;
#}

sub sayit {
	my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}
signal_add("check tubes", "fetch_tubes"); 
#signal_add("search tubes", "search_tubes"); 
