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
                    . add_dots($data->{'confirmed'}) . ' confirmed :: '
                    . add_dots($data->{'recovered'}) . ' recovered :: '
                    . add_dots($data->{'deaths'}   ) . ' deaths :: '
                    . 'https://corona-stats.online/' . uc($country);

     }
     else {
       $output = "$country is not a valid country code. https://corona-stats.online";
     }
    sayit($server, $chan, $output);
  }
  else {
    print (CRAP Dumper($fetched));
    sayit($server, $chan, 'nope, try later ‾\(°_o)/‾');
  }
}
sub add_dots {
  my $n = scalar reverse shift;
  $n =~ s/(\d{3})(?=\d)/$1./g;
  return scalar reverse $n;
}
sub sayit { my $s = shift; $s->command("MSG @_");  }
