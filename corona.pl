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
my $api_url = 'https://corona-stats.online/'; # 'Argentina?format=json';
my $last_fetch = 0;
my $output;

sub fetch_infected {
  my ($server, $chan, $country) = @_;
  my $ua  = LWP::UserAgent->new( timeout => 5 );
  $ua->agent(Irssi::settings_get_str('myUserAgent'));

  my $raw = $ua->get($api_url . $country . '?format=json')->content();
  #print (CRAP Dumper($raw));
  my $fetched = $json->utf8->decode($raw);
  my $data = shift @{$fetched->{'data'}};
  #print (CRAP Dumper($fetched));
  #$last_fetch = time() if $fetched;
  #print (CRAP Dumper($data));
  if ($data) {
    $output = '[' . $data->{'countryInfo'}->{'country'} . '] '
                . $data->{'confirmed'} . ' confirmed :: '
                . $data->{'recovered'} . ' recovered :: '
                . $data->{'deaths'}    . ' deaths :: '
                . 'https://corona-stats.online/' . uc($country);

   }
   else {
     $output = "$country is not a valid country code. https://corona-stats.online";
   }
  sayit($server, $chan, $output);
}
sub sayit { my $s = shift; $s->command("MSG @_");  }
