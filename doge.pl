#WOW SUCH SCRIPT
# http://www.dogeapi.com/api_documentation

use Irssi qw(signal_add print settings_add_str settings_get_str) ;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Data::Dumper;
 
settings_add_str('bot config', 'doge_api',    '');
signal_add('such signal','wow');
signal_add('such difficult','many_hard');

my $wait_for = 1800; #seconds. = 30mins
my $time_fetched = undef;
my $json = new JSON;

my $already_fetched   = undef;
my $doge_price        = undef;
my $api_key   = settings_get_str('doge_api');
my $url       = "https://www.dogeapi.com/wow/v2/?api_key=${api_key}";
my $get_price = '&a=get_current_price';
my $get_difficulty = '&a=get_difficulty';
my $ua        = LWP::UserAgent->new(timeout => '15');

#{{{ WOW SUCH SUB
sub wow {
  my ($server, $chan, $text) = @_;
  my ($muchcoins) = $text =~ /!doge(?:\w+)? (\d+)$/;
  my $last_fetch = $already_fetched ? $time_fetched : 0;
  if (time - $last_fetch > $wait_for) {
    $ua->agent(settings_get_str('myUserAgent'));
    my $ua_got = eval { $ua->get($url . $get_price) };
    return if $@;
    my $decoded_json = eval { $json->utf8->decode($ua_got->decoded_content) };
    return if $@;
    $doge_price = $decoded_json->{data}->{amount};
    $time_fetched = time;
    $already_fetched = 1;
  }
  if ($doge_price != 0 and not $muchcoins) {
    sayit($server, $chan, "wow. such price: 1 Ɖ = \$$doge_price | \$1 = " . 
                          sprintf("%.5f", eval("1/$doge_price")) . 
                          ' dogecoins'
         );
  } 
  elsif (defined($muchcoins) and $muchcoins > 0) {
      sayit($server, $chan, "wow. very rich: \$" . 
                            sprintf("%.2f", eval("$muchcoins * $doge_price"))
           );
  }
  else { 
    $already_fetched = undef; 
  }

}#}}}

sub many_hard {
  my ($server, $chan, $text) = @_;
  $ua->agent(settings_get_str('myUserAgent'));
  my $ua_got = eval { $ua->get($url . $get_difficulty) };
  return if $@;
  my $decoded_json = eval { $json->utf8->decode($ua_got->decoded_content) };
  return if $@;
  my $difficulty = $decoded_json->{data}->{difficulty};
  #print (CRAP Dumper($decoded_json));
  if ($difficulty) {
    sayit($server, $chan, "so much hard: $difficulty");
  }
}


sub sayit { my $s = shift; $s->command("MSG @_"); }
