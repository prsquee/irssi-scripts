#clima.pl
#documentation http://www.wunderground.com/weather/api/d/docs?d=data/index&MR=1
use strict;
use warnings;
use Irssi qw(signal_emit signal_add print settings_get_str settings_add_str);
use LWP::UserAgent;
use Data::Dumper;
use JSON;
use utf8;

settings_add_str('weather', 'weatherkey', '');
signal_add('weather','check_weather');

my $json = new JSON;
my $ua   = new LWP::UserAgent;
$ua->timeout(10);

sub check_weather {
  my ($server,$chan,$city) = @_;
  $city =~ s/\s+/_/g;

  my $apikey = settings_get_str('weatherkey');
  print (CRAP "no weather apikey") unless (defined($apikey));

  my $url = "http://api.wunderground.com/api/${apikey}/conditions/q/${city}_argentina.json";
  $ua->agent(settings_get_str('myUserAgent'));

  my $req = $ua->get($url);
  my $result = eval { $json->utf8->decode($req->decoded_content) };
  return if $@;
  if (defined($result->{current_observation})) {
    my $temp        = $result->{current_observation}->{temp_c};
    my $lowest      = $result->{current_observation}->{dewpoint_c};
    my $weather     = $result->{current_observation}->{weather};
    my $humidity    = $result->{current_observation}->{relative_humidity};
    my $feelslike   = $result->{current_observation}->{feelslike_c};
    my $found_city  = $result->{current_observation}->{display_location}->{full};

    my $out = "${found_city}: ${weather}, feels like: ${temp}˚, min: ${lowest}˚, humidity: ${humidity}";
    sayit($server, $chan, $out);
  } else { sayit($server,$chan,"I really don't care about that city."); }
}
sub sayit { my $s = shift; $s->command("MSG @_"); }

