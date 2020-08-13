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
use Locale::Country;

settings_add_str('weather', 'weatherkey', '');
signal_add('weather','check_weather');

my $apiurl = 'http://api.openweathermap.org/data/2.5/weather?units=metric&appid=' . settings_get_str('weatherkey') . '&';

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
my $ua   = LWP::UserAgent->new( timeout => 5 );

sub check_weather {
  my ($server, $chan, $city) = @_;
  my $url = '';

  if ($city =~ /^\d+$/) {
    $url = $apiurl . 'id=' . $city;
  } else {
    $city = uri_escape($city);
    $url = $apiurl . "q=$city";
    print (CRAP $apiurl);
  }

  $ua->agent(settings_get_str('myUserAgent'));

  my $got = $ua->get($url);
  unless ($got->is_success) {
    my $status = $got->status_line;
    #print (CRAP "clima error code: $status");
    sayit($server,$chan,"error: $status");
    return;
  }
  
  my $parsed = eval { $json->utf8->decode($got->decoded_content) };
  return if $@;

  if ($parsed->{cod} == '200') {
    #my $item = $parsed_json->{list}[0];
    my $temp        = int($parsed->{'main'}->{'temp'});
    my $min         = int($parsed->{'main'}->{'temp_min'});
    my $max         = int($parsed->{'main'}->{'temp_max'});
    my $humidity    = int($parsed->{'main'}->{'humidity'});
    my $found_city  = $parsed->{'name'};
    my $country     = code2country($parsed->{'sys'}->{'country'});
    my $weather     = $parsed->{'weather'}[0];
    my $icon        = $weather->{'icon'};
    my $lat         = $parsed->{'coord'}->{'lat'};
    my $lon         = $parsed->{'coord'}->{'lon'};

    my $out = "${found_city}, ${country}: ${temp}˚C - $weather{$icon} - min: ${min}˚C, max: ${max}˚C - humidity: ${humidity}% ";

    sayit($server, $chan, $out);
  } else { sayit($server,$chan,"city not found."); }
}
sub sayit { my $s = shift; $s->command("MSG @_"); }

