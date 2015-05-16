#youtube stuff
#doc https://developers.google.com/youtube/v3/getting-started

use Irssi qw (signal_add signal_emit print settings_get_str );
use warnings;
use strict;
use Data::Dumper;
use LWP::UserAgent;
use JSON;

#init 
signal_add("check tubes", "fetch_tubes"); 
Irssi::settings_add_str('apikey', 'google_apikey', '');

my %fetched_vids = ();
my $json    = JSON->new();
my $ua      = LWP::UserAgent->new( timeout => '15' );

my $api_url = 'https://www.googleapis.com/youtube/v3/videos?id=';
my $api_key = '&key=' . settings_get_str('google_apikey');
my $part    = '&part=contentDetails,snippet,statistics';
my $field   = '&fields=items('
                          . 'contentDetails(duration),'
                          . 'snippet(title),'
                          . 'statistics(viewCount)'
                          . ')';

sub fetch_tubes {
  my($server, $chan, $vid) = @_;

  if (not exists($fetched_vids{$vid})) {
    my $request_url = $api_url . $vid . $api_key . $part . $field ;

    $ua->agent(settings_get_str('myUserAgent'));
    my $req = $ua->get($request_url);
    my $result = eval { $json->utf8->decode($req->decoded_content) };
    return if $@;

    #items comes as an one element array.
    my $item = shift @{ $result->{'items'} };

    my $title = $item->{'snippet'}->{'title'};
    my $time  = $item->{'contentDetails'}->{'duration'};
    my $views = $item->{'statistics'}->{'viewCount'};

    #print (CRAP "$title - $time - $views");
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

  #time comes in iso 8601 duration format
  #like PT2H11M12S, if the vid is longer than a day: P2DT2H11M12S
  #we match all the integers and start from the last element, seconds.
  my @integers = $time =~ /(\d+)/g;
  
  $time = join(':', map { sprintf("%02d", $_) } @integers);

  $time = 'live' if $time eq '00';
  $time = '00:' . $time if $time !~ /:/;
  $time = '[' . $time . ']';
  return $time;
}
sub sayit { my $s = shift; $s->command("MSG @_"); }

