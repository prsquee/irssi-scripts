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

my $json = JSON->new();
my $ua   = LWP::UserAgent->new( timeout => 15 );

sub check_weather {
  my ($server, $chan, $city) = @_;
  $city =~ s/\s+/_/g;

  my $apikey = settings_get_str('weatherkey');
  print (CRAP "no weather apikey") unless (defined($apikey));

  my $url = "http://api.wunderground.com/api/${apikey}/conditions/q/${city}.json";
  $ua->agent(settings_get_str('myUserAgent'));

  my $got = $ua->get($url);
  unless ($got->is_success) {
    print (CRAP "clima error code: $got->code - $got->message");
    return;
  }
  
  my $parsed_json = eval { $json->utf8->decode($got->decoded_content) };
  return if $@;

  if (defined($parsed_json->{current_observation})) {
    my $temp        = $parsed_json->{current_observation}->{temp_c};
    my $lowest      = $parsed_json->{current_observation}->{dewpoint_c};
    my $weather     = $parsed_json->{current_observation}->{weather};
    my $humidity    = $parsed_json->{current_observation}->{relative_humidity};
    my $feelslike   = $parsed_json->{current_observation}->{feelslike_c};
    my $found_city  = $parsed_json->{current_observation}->{display_location}->{full};

    my $out = "${found_city}: ${weather}, feels like: ${temp}˚, min: ${lowest}˚, humidity: ${humidity}";
    sayit($server, $chan, $out);
  } else { sayit($server,$chan,"I really don't care about that city."); }
}
sub sayit { my $s = shift; $s->command("MSG @_"); }

