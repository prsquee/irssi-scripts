#dolar3.plA

use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use LWP::UserAgent;
use utf8;
use strict;
use warnings;
use Data::Dumper;
use JSON;

#{{{ init and stuff

my %fetched_prices     = ();
my $last_fetch = 0;
my $bufferme   = '20'; 

my $json = JSON->new();
my $bluelytics_url = 'http://api.bluelytics.com.ar/v2/latest';

sub fetch_price {
  my $url = shift;
  my $ua  = LWP::UserAgent->new( timeout => 9 );
  $ua->agent(Irssi::settings_get_str('myUserAgent'));

  my $raw_result = $ua->get($url)->content();
  %fetched_prices = %{ $json->utf8->decode($raw_result) };

  $last_fetch = time() if %fetched_prices;
}
#}}}
sub format_currency {
  my ($type, $prices_ref) = @_;

  my @exchanges = qw(oficial blue);

  @exchanges = map { $_ . '_euro' } @exchanges if ($type eq 'euro');

  my $output = '';

  foreach my $type (@exchanges) {
    $output .= '[' . ucfirst($type) . '] $'  . sprintf("%.1f", $prices_ref->{$type}->{'value_buy' })
                                    .' - $'  . sprintf("%.1f", $prices_ref->{$type}->{'value_sell'})
                                    . ' :: ';
  }
  $output .= '[Solidario] $' . sprintf("%.1f", eval($prices_ref->{$exchanges[0]}->{'value_sell'} * 1.3));
  return $output;
}
#{{{ do_dolar
sub do_euros {
  my ($server, $chan, $text) = @_;
  my ($how_much) = $text =~ /^!\w+\s+?(\d+(?:\.\d{1,2})?)?/;

  fetch_price($bluelytics_url) if (time() - $last_fetch > $bufferme);

  if (!$how_much) {
    sayit($server, $chan, format_currency('euro',   \%fetched_prices));
  }
  else {
    my %calculated_prices;

    foreach my $type (keys %fetched_prices) {
      next if ($type eq 'last_update');
      foreach my $value (keys %{$fetched_prices{$type}}) {
        $calculated_prices{$type}->{$value} = $fetched_prices{$type}->{$value} * $how_much;
      }
    }
    sayit($server, $chan, format_currency('euro',   \%calculated_prices));
  }
  return;
}
#}}}
#{{{ signal and stuff
sub sayit { my $s = shift; $s->command("MSG @_"); }
signal_add("showme the euros","do_euros");
#}}}
