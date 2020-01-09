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

sub get_price {
  my $url = shift;
  my $ua  = LWP::UserAgent->new( timeout => 9 );
  $ua->agent(Irssi::settings_get_str('myUserAgent'));

  my $raw_result = $ua->get($url)->content();
  %prices = %{ $json->utf8->decode($raw_result) };


  $last_fetch = time() if %prices;
  #print (CRAP Dumper(%prices));
}
#}}}

#{{{ do_dolar
sub do_dolar {
  my ($server, $chan, $text) = @_;
  my ($ask, $how_much) = $text =~ /^!(\w+)(\s+\d+(?:\.\d{1,2})?)?/;

  get_price($bluelytics_url) if (time() - $last_fetch > $bufferme);

  if ($ask =~ /^dol[oae]r$/) {
    if (!$how_much) {
      my $output = '[Oficial] $' . sprintf("%.1f", $prices{'oficial'}->{'value_buy'})
                        . ' - $' . sprintf("%.1f", $prices{'oficial'}->{'value_sell'})
                 . ' :: '
                 . '[Blue] $'    . sprintf("%.1f", $prices{'blue'}->{'value_buy'})
                        . ' - $' . sprintf("%.1f", $prices{'blue'}->{'value_sell'})
                 . ' :: '
                 . '[Solidario] $' . sprintf("%.1f", eval($prices{'oficial'}->{'value_sell'} * 1.3));

      sayit($server, $chan, $output);
    }
  } 
  elsif ($ask =~ /^euros?$/) {
    my $euros = '[Euro Oficial] $' . sprintf("%.1f", $prices{'oficial_euro'}->{'value_buy'})
                     . ' - $' . sprintf("%.1f", $prices{'oficial_euro'}->{'value_sell'})
               . ' :: '
               . '[Euro Blue] $'   . sprintf("%.1f", $prices{'blue_euro'}->{'value_buy'})
                     . ' - $' . sprintf("%.1f", $prices{'blue_euro'}->{'value_sell'})
               . ' :: '
               . '[Euro Solidario] $' . sprintf("%.1f", eval($prices{'oficial_euro'}->{'value_sell'} * 1.3));

    sayit($server, $chan, $euros);
  }
  return;
}
#}}}

#{{{ signal and stuff
sub sayit { my $s = shift; $s->command("MSG @_"); }
signal_add("showme the money","do_dolar");
#}}}
