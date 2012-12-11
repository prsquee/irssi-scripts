#uptime 
use Irssi qw (  print
                signal_emit
                signal_add
                signal_register
                settings_get_str
                settings_add_str
                settings_set_str
);
use strict;
use warnings;
#use Data::Dumper;

sub get_uptime {
  my ($server,$chan) = @_;
	my ($upD,$upH,$upM) = `uptime` =~ /up (?:(\d+) days?,)?\s+(\d+):(\d+),/;
#	my $record = `cat ~/.uptime_record`;# chomp($record);
	$upD = 0 if (!$upD);
	my $day = "day"; $day .= "s" if ($upD > 1);
	my $hs = "h"; $hs .= "s" if ($upH > 1);
	my $min = "min"; $min .= "s" if ($upM > 1);
	my $uptime = "$upD $day $upH $hs $upM $min";
  sayit($server,$chan,$uptime);
  return;
}

sub sayit {
	my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}
signal_add('show uptime', 'get_uptime');
