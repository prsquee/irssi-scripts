# feriados
use Irssi qw(signal_add print settings_add_str settings_get_str);
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Data::Dumper;
use DateTime;

use utf8;
use Encode qw (encode decode);

#init
signal_add("worknowork", "fetch_holidays");

my $json = JSON->new();
my $api_url = 'http://nolaborables.com.ar/api/v2/feriados/';
my $last_fetch = 0;

my @meses = ('Enero', 'Febrero', 'Marzo', 'Abril','Mayo','Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre');

sub fetch_holidays {
  my ($server, $chan) = @_;
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  $year += 1900;

  my $ua  = LWP::UserAgent->new( timeout => 5 );
  $ua->agent(Irssi::settings_get_str('myUserAgent'));

  my $raw = $ua->get($api_url . $year . '?formato=mensual')->content();
  my $holidays = $json->utf8->decode($raw);

  my $today = new_dt($year,$mon,$mday);

  # go to a month that has a holiday
  unless (%{$$holidays[$mon]}) {
    $mon += 1;
  }

  my $output = undef;
  foreach my $day (sort {$a <=> $b} keys %{$$holidays[$mon]}) {
    my $this_holiday = new_dt($year,$mon,$day);
    next if ($today > $this_holiday);

    if ($today == $this_holiday) {
      $output = 'HOY ES FERIADO! ';
    }
    else {
      my $delta = $today->delta_days($this_holiday)->delta_days();
      $output = $delta == 1 ? 'MAÑANA ES FERIADO! ' : "Faltan $delta días para el $day de $meses[$mon]: ";
    } 
    if ($output and $$holidays[$mon]{$day}->{'tipo'} eq 'puente') {
      $day += 1;
      $output .= "Feriado puente con el $day de $meses[$mon]: ";
    }
    sayit($server, $chan, $output . "$$holidays[$mon]{$day}->{'motivo'}.");
    return;
  }
  sayit($server,$chan, 'no hay más feriados hasta el próximo año.') unless $output;
}

sub new_dt {
  my ($y,$m,$d) = @_;
  $m += 1;
  return DateTime->new(
    year => $y, month  => $m, day    => $d,
    hour => 13, minute => 37, second => 42,
    time_zone => 'UTC'
  );
}
sub sayit { my $s = shift; $s->command("MSG @_"); }
