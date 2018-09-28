#estado de subte

use Irssi qw(signal_add print settings_add_str settings_get_str) ;
use strict;
use warnings;
use Data::Dumper;
use XML::LibXML;
use utf8;
 
settings_add_str('bot config', 'subte_agent', '');
settings_add_str('bot config', 'subte_url',   '');

signal_add('hay subte', 'check_subte');

my $buffered_for  = 480;    #secs. ~8mins
my $last_fetched  = 0;
my %subtes;

my $ua = LWP::UserAgent->new(
  timeout  => 10,
  agent    => settings_get_str('subte_agent')
);
#{{{
sub check_subte {
  my ($server, $chan, $linea) = @_;
  fetch_status() if (time - $last_fetched > $buffered_for);
  #my $output = "[Línea $linea] \x02$subtes{$linea}->{status}\x02";
  my $output = "[Línea $linea] " . $subtes{$linea}->{status};
  if ($subtes{$linea}->{freq}) {
     $output .= ' - cada ' . int($subtes{$linea}->{freq} / 60) . ' mins';
   }
   sayit ($server, $chan, $output);
  return;
}#}}}

sub fetch_status {
  my $dom = XML::LibXML->load_xml(location => settings_get_str('subte_url'));
  foreach my $line ($dom->findnodes('/Reporte/Linea')) {
    my $name = substr($line->findvalue('./nombre'), -1);
    my $freq = $line->findvalue('./frecuencia');
    if ($freq =~ /^\d+$/ ) {
      $subtes{$name} = {
        'status' => 'OK',
        'freq' => $freq
      };
    }
    else {
      $subtes{$name} = {
        'status' => $line->findvalue('./estado'),
        'freq' => undef
      };
    }
  }
  $last_fetched = time();
  return;
}
sub sayit { $_ = shift; $_->command("MSG @_"); }
