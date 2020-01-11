#dolar3.plA

use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use LWP::UserAgent;
use utf8;
use strict;
use warnings;
use Data::Dumper;
use JSON;

#{{{ init and stuff

my %prices     = ();
my $last_fetch = 0;
my $bufferme   = '10';  #30mins

my $json = JSON->new();
my $bluelytics_url = 'http://api.bluelytics.com.ar/v2/latest';

sub fetch_price {
  my $url = shift;
  my $ua  = LWP::UserAgent->new( timeout => 9 );
  $ua->agent(Irssi::settings_get_str('myUserAgent'));

  my $raw_result = $ua->get($url)->content();
  %prices = %{ $json->utf8->decode($raw_result) };

  $last_fetch = time() if %prices;
  #print (CRAP Dumper(%prices));
}
#}}}
sub calc_currency {
  my @types = qw(oficial blue);
  @types = map { $_ . '_euro' } @types if (shift(@_) eq 'euro');

  my $output = '';
  foreach my $type (@types) {
    $output .= '[' . ucfirst($type) . '] $'  . sprintf("%.1f", $prices{$type}->{'value_buy' }) 
                                    .' - $'  . sprintf("%.1f", $prices{$type}->{'value_sell'})
                                    . ' :: ';
  }
  $output .= '[Solidario] $' . sprintf("%.1f", eval($prices{$types[0]}->{'value_sell'} * 1.3));
  return $output;
}
#{{{ do_dolar
sub do_dolar {
  my ($server, $chan, $text) = @_;
  my ($ask, $how_much) = $text =~ /^!(\w+)(\s+\d+(?:\.\d{1,2})?)?/;

  fetch_price($bluelytics_url) if (time() - $last_fetch > $bufferme);

  if ($ask =~ /^dol[oae]r$/) {
    my $output = calc_currency('dollar');
    #if (!$how_much) {
    sayit($server, $chan, $output);
  } 
  elsif ($ask =~ /^euros?$/) {
    my $euros = calc_currency('euro');
    sayit($server, $chan, $euros);
  }
  return;
}
#}}}
#{{{ signal and stuff
sub sayit { my $s = shift; $s->command("MSG @_"); }
signal_add("showme the money","do_dolar");
#}}}
