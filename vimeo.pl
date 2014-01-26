#isohunt
use Irssi qw(settings_get_str signal_emit signal_add print);
use warnings;
use strict;
use Data::Dumper;
use LWP::UserAgent;
use JSON;
use Data::Dump;

our %vimeos = ();
my $json = new JSON;
$json = $json->utf8([1]);
my $ua = new LWP::UserAgent;
$ua->timeout( 10 );
my $query = 'http://vimeo.com/api/v2/video/'; 

sub check_vimeo {
  my ($server,$chan,$vid) = @_;
  $ua->agent(settings_get_str('myUserAgent'));
  $query = $query . $vid . '.json';
  my $req = $ua->get( $query );
  #my $content = $got->decoded_content;
  my $result = shift(eval { $json->utf8->decode($req->decoded_content) } );
  return if $@;
  my $time = $result->{'duration'};
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
  my $user = $result->{'user_name'};
  my $title = $result->{'title'};
  #my $desc = $result->{'description'}; #this is too long sometimes
  my $out = "$time \x02$title\x02 - Uploaded by $user";
  sayit($server, $chan, $out);
  $vimeos{$vid} = $out;
}
sub sayit { my $s = shift; $s->command("MSG @_"); }
signal_add("check vimeo","check_vimeo");
