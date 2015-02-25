#isohunt
use Irssi qw(settings_get_str signal_emit signal_add print);
#use warnings;
use strict;
use Data::Dumper;
use LWP::UserAgent;
use JSON;
use URI::Encode qw(uri_encode uri_decode);

signal_add("cuac cuac go","cuac_cuac");

my $json = JSON->new();
$json = $json->utf8([1]);
my $ua = LWP::UserAgent->new(timeout => '15');

sub cuac_cuac {
  my ($server, $chan, $searchme) = @_;
  my $query = 'https://api.duckduckgo.com/?q=' . uri_encode($searchme) . '&format=json';
  $ua->agent(settings_get_str('myUserAgent'));

  my $raw_results = $ua->get($query)->decoded_content;
  my $parsed_json = eval { $json->allow_nonref->utf8->decode($raw_results) };
  return if $@;
  print (CRAP Dumper($parsed_json));
  sayit($server, $chan, '[Answer] '  . $parsed_json->{'Answer'})      if ($parsed_json->{'Answer'});
  sayit($server, $chan, '[def] '     . $parsed_json->{'Definition'})  if ($parsed_json->{'Definition'});
  sayit($server, $chan, '[Abstract]' . $parsed_json->{'Abstract'})    if ($parsed_json->{'Abstract'});
  return;
}

sub sayit { my $s = shift; $s->command("MSG @_"); }
