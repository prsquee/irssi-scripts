use Irssi qw (print signal_add);
use strict;
use warnings;
use Data::Dumper;

signal_add('show uptime', 'get_uptime');

sub get_uptime {
  my ($server,$chan) = @_;
  my ($days, $hour, $mins) 
    = qx(/usr/bin/uptime) 
      =~ /up (?:(\d+) days?,)?\s+(\d+):(\d+),/;

  $days = 0 if not $days;
  $hour = 0 if not $hour;

  my $uptime = $days . ' day'    . (($days > 1) ? 's ' : ' ')
             . $hour . ' hour'   . (($hour > 1) ? 's ' : ' ')
             . $mins . ' mintue' . (($mins > 1) ? 's ' : ' ')
             ;
  sayit($server, $chan, $uptime);
}

sub sayit { my $s = shift; $s->command("MSG @_"); }
