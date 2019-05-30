#clima.pl
# using openweathemap now: https://openweathermap.org/current
#
use strict;
use warnings;
use Irssi qw(signal_emit signal_add print settings_get_str settings_add_str);
use LWP::UserAgent;
use URI::Escape;
use Data::Dumper;
use JSON;
use utf8;

settings_add_str('weather', 'weatherkey', '');
signal_add('weather','check_weather');

my $apiurl = 'http://api.openweathermap.org/data/2.5/find?q=';
my $apikey = '&units=metric&APPID=' . settings_get_str('weatherkey');

my %weather = (
  '01d' => '☀️',
  '01n' => '🌙',
  '02d' => '🌥',
  '02n' => '🌥',
  '03d' => '☁️',
  '03n' => '☁️',
  '04d' => '☁️',
  '04n' => '☁️',
  '09d' => '🌦',
  '09n' => '🌦',
  '10d' => '🌧',
  '10n' => '🌧',
  '11d' => '⛈',
  '11n' => '⛈',
  '13d' => '🌨',
  '13n' => '🌨',
  '50d' => '🌫',
  '50n' => '🌫',
);

my $json = JSON->new();
my $ua   = LWP::UserAgent->new( timeout => 15 );

sub check_weather {
  my ($server, $chan, $city) = @_;
  $city = uri_escape($city);

  my $url = $apiurl . $city . $apikey;
  $ua->agent(settings_get_str('myUserAgent'));

  my $got = $ua->get($url);
  unless ($got->is_success) {
    print (CRAP "clima error code: $got->code - $got->message");
    return;
  }
  
  my $parsed_json = eval { $json->utf8->decode($got->decoded_content) };
  return if $@;

  if ($parsed_json->{cod} == '200' and $parsed_json->{count} > 0) {
    my $item = $parsed_json->{list}[0];
    my $temp        = int($item->{main}->{temp});
    my $min         = int($item->{main}->{temp_min});
    my $max         = int($item->{main}->{temp_max});
    my $humidity    = int($item->{main}->{humidity});
    my $found_city  = $item->{name};
    my $weather     = $item->{weather}[0];
    my $icon        = $weather->{icon};

    my $out = "${found_city}: ${temp}˚C - $weather{$icon} - min: ${min}˚C, max: ${max}˚C - humidity: ${humidity}% ";

    sayit($server, $chan, $out);
  } else { sayit($server,$chan,"city not found."); }
}
sub sayit { my $s = shift; $s->command("MSG @_"); }

