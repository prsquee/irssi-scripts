#bitcoins 
#https://www.bitstamp.net/api/ticker/

use Irssi qw(signal_add print settings_get_str) ;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Data::Dumper;
 
signal_add('gold digger','bitstamp');

my $buffer = 1800;
my $fetched = undef;
my $json = new JSON;

my $bitstamp    = undef;
my $url = 'https://www.bitstamp.net/api/ticker';
my $ua    = new LWP::UserAgent;
$ua->timeout(15);


sub bitstamp {
  my ($server, $chan) = @_;
  #if (time - $fetched{$bitstamp} > 60 or not defined($bitstamp)) {
  my $t = defined($bitstamp) ? $fetched : 0;
  if (time - $t > $buffer) {
    $ua->agent(settings_get_str('myUserAgent'));
    my $req = $ua->get($url);
    my $r = eval { $json->utf8->decode($req->decoded_content) };
    return if $@;
    if ($r and not $@) {
      $bitstamp  = '[Bitstamp] ';
      $bitstamp .= 'high: $' . $r->{high} . ' | ';
      $bitstamp .= 'low: $' .  $r->{low}  . ' | ';
      $bitstamp .= 'average: $' . sprintf("%.2f", eval("($r->{bid} + $r->{ask}) / 2"));
      $fetched = time();
    } else { $bitstamp = undef; }
    #print (CRAP Dumper($r)) 
  }
  sayit ($server, $chan, $bitstamp) if (defined($bitstamp));
  return;
}

sub sayit { my $s = shift; $s->command("MSG @_"); }

