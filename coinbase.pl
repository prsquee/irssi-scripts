# coinbase public api
# FIX ME this is getting out of hands
use Irssi qw(signal_add print settings_add_str settings_get_str);
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Data::Dumper;
use DateTime;
use utf8;
use Encode qw (encode decode);

#init
signal_add("gold digger", "fetch_coins");

my $json = JSON->new();
my $api_url = 'https://api.coinbase.com/v2/prices/spot?currency=USD';
my $last_fetch = 0;


sub fetch_coins {
  my ($server, $chan, $this_much) = @_;
  my $ua  = LWP::UserAgent->new( timeout => 5 );
  $ua->agent(Irssi::settings_get_str('myUserAgent'));

  my $output = '';

  my $raw = $ua->get($api_url)->content();
  my $coins = $json->utf8->decode($raw);
  my $coinbase_price = $coins->{'data'}->{'amount'};
  $output = '[coinbase] $' . sprintf("%.2f", eval($coinbase_price * $this_much));

  my $kraken_price = scalar('Irssi::Script::kraken')->can('fetch_prices_for')->('btc') if is_loaded('kraken');
  $output .= ' :: [kraken] $' . sprintf("%.2f", eval($kraken_price * $this_much)) if ($kraken_price);

  my $bitfinex_price = scalar('Irssi::Script::bitfinex')->can('fetch_price')->() if is_loaded('bitfinex');
  $output .= ' :: [bitfinex] $' . sprintf("%.2f", eval($bitfinex_price * $this_much)) if ($bitfinex_price);

  my $binance_price = scalar('Irssi::Script::binance')->can('fetch_price')->() if is_loaded('binance');
  $output .= ' :: [binance] $' . sprintf("%.2f", eval($binance_price * $this_much)) if ($binance_price);

  # $output .= ' :: [bitfinex] $' . sprintf("%.2f", eval($bitfinex_price * $this_much)) if ($bitfinex_price);
  my $bitso_price = scalar('Irssi::Script::bitso')->can('fetch_price')->() if is_loaded('bitfinex');
  $output .= ' :: [bitso] $' . sprintf("%.2f", eval($bitso_price * $this_much)) if ($bitso_price);
  sayit($server, $chan, $output);
}
sub sayit { my $s = shift; $s->command("MSG @_"); }
sub is_loaded { return exists($Irssi::Script::{shift(@_).'::'}); }

