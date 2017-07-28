use Irssi qw (print signal_add);
use strict;
use warnings;
use Data::Dumper;
use Unix::Uptime;

signal_add('show uptime', 'get_uptime');

sub get_uptime {
  my ($server,$chan) = @_;
  my $uptime_days = 'about '
                  . sprintf ("%d", Unix::Uptime->uptime() / 86400)
                  . ' days.'
                  ;
  sayit($server, $chan, "$uptime_days");
}

sub sayit { my $s = shift; $s->command("MSG @_"); }
