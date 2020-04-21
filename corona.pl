use Irssi qw(signal_add print settings_add_str settings_get_str);
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Data::Dumper;
use WWW::Shorten::TinyURL;
use utf8;

#init
signal_add("coronavirus", "fetch_infected");

my $json = JSON->new();
my $api_url = 'https://corona-stats.online/';
my $jumbo_url = 'https://www.jumbo.com.ar/api/catalog_system/pub/products/search/?fq=skuId:22487';
my $last_fetch = 0;
my $output;

sub fetch_infected {
  my ($server, $chan, $country) = @_;
  my $ua  = LWP::UserAgent->new( timeout => 5 );
  $ua->agent(Irssi::settings_get_str('myUserAgent'));

  my $raw = $ua->get($api_url . $country . '?format=json')->content();
  my $fetched = undef;
  eval { $fetched = $json->utf8->decode($raw) };
  unless ($@) {
    my $data = shift @{$fetched->{'data'}};
    if ($data) {
      $output = '[' . $data->{'country'} . '] '
                    . $data->{'confirmed'} . ' confirmed :: '
                    . $data->{'recovered'} . ' recovered :: '
                    . $data->{'deaths'}    . ' deaths :: '
                    . 'https://corona-stats.online/' . uc($country);

     }
     else {
       $output = "$country is not a valid country code. https://corona-stats.online";
     }
    sayit($server, $chan, $output);
    if (int(rand(12)) == 4) {
      my $beer_price = fetch_beer();
      sayit($server, $chan, "Una erveza Corona rubia de 330cc sale \$$beer_price en Jumbo.");
    }
  }
  else {
    print (CRAP Dumper($fetched));
    sayit($server, $chan, 'nope, try later ‾\(°_o)/‾');
  }
}
sub fetch_beer {
  my $ua  = LWP::UserAgent->new( timeout => 5 );
  $ua->agent(Irssi::settings_get_str('myUserAgent'));
  my $raw = $ua->get($jumbo_url)->content();
  my $beer_json = $json->utf8->decode($raw);
  return $$beer_json[0]->{'items'}[0]->{'sellers'}[0]->{'commertialOffer'}->{'ListPrice'};
}
sub sayit { my $s = shift; $s->command("MSG @_");  }
