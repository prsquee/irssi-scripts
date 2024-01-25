# feriados
use Irssi qw(signal_add print settings_add_str settings_get_str);
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Data::Dumper;
use DateTime;
use Scalar::Util;

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
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
  $year += 1900;

  my $ua  = LWP::UserAgent->new( timeout => 5 );
  $ua->agent(Irssi::settings_get_str('myUserAgent'));

  my $raw = $ua->get($api_url . $year)->content();
  my $holidays_unsorted = $json->utf8->decode($raw);
  #print (CRAP Dumper($holidays_unsorted));

  #format=mensual doesnt work anymore, convert it manually:
  # @months is a 12 elemtns array, where each member is a hash table containing the holidays for that month:
  # if a month doesnt have a holiday, it should be empty.

  my @months = map { {} } (1..12);
  foreach my $holiday (@{$holidays_unsorted}) {
    $months[$holiday->{'mes'} - 1]->{$holiday->{'dia'}} = $holiday;
  }

  my $today = new_dt($year, $mon, $mday);

  # go to a month that has a holiday
  while (not %{$months[$mon]}) {
    $mon += 1;
  }

  my $output = undef;
  while (not defined($output)) {
    foreach my $day (sort {$a <=> $b} keys %{$months[$mon]}) {
      my $this_holiday = new_dt($year,$mon,$day);
      next if ($today > $this_holiday);
      next if ($this_holiday->day_of_week =~ /[67]/);

      if ($today == $this_holiday) {
        $output = 'HOY ES FERIADO! ';
      }
      else {
        my $delta = $today->delta_days($this_holiday)->delta_days();
        $output = $delta == 1 ? 'MAÑANA ES FERIADO! ' : "Faltan $delta días para el $day de $meses[$mon]: ";
      }
      # check ref type before accessing 'tipo'. There could be a rare two holidays on the same day.
      if ($output and $months[$mon]{$day}->{'tipo'} eq 'puente') {
        #puente could be very unlikely a day before
        if ($months[$mon]{$day - 1}->{'motivo'}) {
          $day -= 1;
          $output .= " Feriado puente con el $day de $meses[$mon]. ";
        }
        #the most likey case is the next day
        elsif ($months[$mon]{$day + 1}->{'motivo'}) {
          $day += 1;
          $output .= " Feriado puente con el $day de $meses[$mon]. ";
        }
        # an edge case, puente is on a friday, then go to monday
        elsif ($this_holiday->day_name eq 'Friday' and $months[$mon]{$day + 3}->{'motivo'}) {
          $day += 3;
          $output .= " Feriado puente con el $day de $meses[$mon]. ";
        }
      }
      sayit($server, $chan, $output . "$months[$mon]{$day}->{'motivo'}.");
      return;
    }
    $mon += 1 unless $output;
    if ($mon == 12) {
      sayit($server,$chan, 'no hay más feriados hasta el próximo año.');
      return;
    }
  }
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
