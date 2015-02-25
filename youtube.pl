#check youtube title and desc
use Irssi qw (signal_add signal_emit print settings_get_str );
use warnings;
use strict;
use Data::Dumper;
use LWP::UserAgent;
use JSON;

#init 
signal_add("check tubes", "fetch_tubes"); 

my %fetched_vids = ();
my $json = JSON->new();
my $ua   = LWP::UserAgent->new( timeout => '15' );
my $api_url = 'http://gdata.youtube.com/feeds/api/videos/'; 

sub fetch_tubes {
  my($server, $chan, $vid) = @_;

  if (not exists($fetched_vids{$vid})) {
    my $url = $api_url . $vid . '?&v=2&alt=json';
    $ua->agent(settings_get_str('myUserAgent'));
    my $req = $ua->get($url);
    my $result = eval { $json->utf8->decode($req->decoded_content)->{entry} };
    return if $@;

    my $title = $result->{title}->{'$t'};
    my $desc  = $result->{'media$group'}->{'media$description'}->{'$t'};
    my $time  = $result->{'media$group'}->{'yt$duration'}->{seconds};
    my $views = $result->{'yt$statistics'}->{'viewCount'};

    if ($title) {
      #print (CRAP $time);
      $time = format_time($time);
      my $vid_info = "${time} ${title} - [views $views]";
      sayit($server, $chan, $vid_info);

      $fetched_vids{$vid} = $vid_info;
    } 
    else { return; }
  } 
  else { sayit ($server, $chan, $fetched_vids{$vid}); }
}

sub format_time {
  my $time = shift;
  my $hour = undef;
  my $mins = '00';
  my $secs = 0;

  if ($time > 0) {
    $hour = sprintf ("%02d", $time/3600) if $time >= 3600;
    $time = $time - 3600 * int($hour) if $hour;
    if ($time >= 60) {
      $mins = sprintf ("%02d", $time/60);
      $secs = sprintf ("%02d", $time%60);
    } 
    elsif ($time < 60) {
      $secs = sprintf("%02d", $time);
    }
    $time = "${mins}:${secs}";
    $time = "${hour}:${time}" if ($hour);
    $time = "[${time}]";
  } 
  else {
    $time = '[LIVE]';
  }
  return $time;
}
sub sayit { my $s = shift; $s->command("MSG @_"); }

