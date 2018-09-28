#dolar2.pl

use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use LWP::UserAgent;
use utf8;
use strict;
use warnings;
use Data::Dumper;

#{{{ init and stuff

my $last_fetch = 0;
my $bufferme   = '10';
my $url        = 'http://ws.geeklab.com.ar/dolar/get-dolar-json.php';
my $price = undef;

sub get_price {
  my $ua = LWP::UserAgent->new( timeout => 10 );
  $ua->agent(Irssi::settings_get_str('myUserAgent'));

  my $raw_result = $ua->get($url)->content();
  #print (CRAP $raw_result);
  $last_fetch = time() if ($raw_result);
  ($price) = $raw_result =~ /"libre":"([^"]+)",/ ;
  return;
}
#}}}

#{{{ do_dolar
sub do_dolar {
  my ($server, $chan, $text) = @_;
  get_price() if (time() - $last_fetch > $bufferme);

  sayit($server, $chan, "[libre] $price") if (!$@);
  return;
}
#}}}

#{{{ signal and stuff
sub sayit { my $s = shift; $s->command("MSG @_"); }
signal_add("showme the money","do_dolar");
#}}}
