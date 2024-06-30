# feriados
# curl -X GET https://api.argentinadatos.com/v1/feriados/2024
use Irssi qw(signal_add print settings_add_str settings_get_str get_irssi_dir);
use strict;
use utf8;
use warnings;
use DateTime::Format::Strptime;
use JSON qw( decode_json );
use File::Slurp;

#init
signal_add("worknowork", "fetch_holidays");

my $json = JSON->new();
my $json_file = get_irssi_dir() . '/scripts/datafiles/feriados.json';
my $holiday_json = read_file($json_file) or return;
my $decoded_holidays = decode_json($holiday_json);
my $date_parser = DateTime::Format::Strptime->new(
    locale    => 'es',
    pattern   => '%Y-%m-%d',
    on_error  => 'croak',
);

sub fetch_holidays {
  my ($server, $chan) = @_;
  my $today = DateTime->now;
  $today->set_time_zone('America/Argentina/Buenos_Aires');
  my $next_holiday_date;
  my $next_holiday_name;
  my $when = '';

  foreach my $holiday (@$decoded_holidays) {
    my $holiday_date = $date_parser->parse_datetime($holiday->{fecha});
    if ($holiday_date > $today && (!defined $next_holiday_date || $holiday_date < $next_holiday_date)) {
      $next_holiday_date = $holiday_date;
      $next_holiday_name = $holiday->{nombre};
    }
  }

  if (defined $next_holiday_name) {
    if ($today == $next_holiday_date) {
      $when = 'HOY ES FERIADO! ';
    }
    else {
      my $delta = $next_holiday_date->delta_days($today)->in_units('days');
      $when = $delta == 1 ? 'MAÑANA ES FERIADO! ' : "Faltan $delta días para el " . $next_holiday_date->day . " de " . ucfirst($next_holiday_date->month_name) . ": ";
    }
    sayit($server, $chan, $when . $next_holiday_name . '.');
  }
  else {
    sayit($server, $chan, "No hay más feriados.");
  }
}

sub sayit { my $s = shift; $s->command("MSG @_"); }
