#isohunt
use Irssi qw(settings_get_str signal_emit signal_add print);
use warnings;
use strict;
use Data::Dumper;
use LWP::UserAgent;
use JSON;
use Data::Dump;

my $json = new JSON;
$json = $json->utf8([1]);
my $ua = new LWP::UserAgent;
$ua->agent(settings_get_str('myUserAgent'));
$ua->timeout( 10 );

our %vimeos = ();

sub check_vimeo {
  my ($server,$chan,$vid) = @_;

  my $query = "http://vimeo.com/api/v2/video/${vid}.json";

  my $req = $ua->get( $query );
  #my $content = $got->decoded_content;
  my $json_text = shift(eval {$json->utf8->decode($req->decoded_content)});
  #print (CRAP Dumper($json_text));
  #return;
  if ($json_text and not $@) {
    my $time = $json_text->{'duration'};
    my $hour = ($time >= 3600) ? sprintf ("%02d:", $time/3600) : undef;
    $time = $time - 3600 * int($hour) if defined($hour);
    my $mins = '00:';
    my $secs = undef;
    if ($time >= 60) {
      $mins = sprintf ("%02d:", $time/60);
      $secs = sprintf ("%02d",  $time%60);
    } elsif ($time < 60) {
      $secs = sprintf("%02d", $time);
    }
    $time = '[';
    $time .= $hour if defined($hour);
    $time .= $mins if defined($mins);
    $time .= $secs if defined($secs);
    $time .= ']'; 
    my $user = $json_text->{'user_name'};
    my $title = $json_text->{'title'};
    #my $desc = $json_text->{'description'}; #this is too long sometimes
    my $out = "$time \x02$title\x02 - Uploaded by $user";
    sayit($server, $chan, $out);
    $vimeos{$vid} = $out;
  }
}
sub sayit { my $s = shift; $s->command("MSG @_"); }
signal_add("check vimeo","check_vimeo");
