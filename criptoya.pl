# criptoya: https://criptoya.com/api/btc/usd/0.5

use Irssi qw(signal_add print settings_get_str settings_add_str) ;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Data::Dumper;

signal_add("criptoya", "do_criptoya");

my @exchanges = qw(buenbit fiwind lemoncash bitsoalpha ripio argenbtc binancep2p belo letsbit);
my $api = 'https://criptoya.com/api/btc/ARS/0.5';
my $bufferme = 300;
my $last_fetch = 0;

my $json = JSON->new();
my $parsed_json = '';
my $ua  = LWP::UserAgent->new( timeout => 15 );
$ua->agent(settings_get_str('myUserAgent'));

sub fetch_json {
  my $got = $ua->get($api);
  unless ($got->is_success) {
    print (CRAP "request error");
    return;
  }
  $parsed_json = eval { $json->utf8->decode($got->decoded_content) };
  $last_fetch = time() if ($parsed_json->{'success'});
}

sub do_criptoya {
  my ($server, $chan) = @_;
  my $output = '';

  fetch_json() if (time() - $last_fetch > $bufferme);

  foreach my $exchange (@exchanges) {
    $output .= '[' . $exchange . '] ' 
              . 'AR$' . add_dots(int($parsed_json->{$exchange}->{'bid'})) . '/'
              . 'AR$' . add_dots(int($parsed_json->{$exchange}->{'ask'})) . ' :: ';
  }
  sayit($server, $chan, $output);
}

sub add_dots {
  my $n = shift;
  return $n if $n =~ /^\d{4}$/;
  $n =~ s/(?<=\d)(?=(\d{3})+(?!\d))/./g;
  return $n;
}

sub sayit { my $s = shift; $s->command("MSG @_"); }
