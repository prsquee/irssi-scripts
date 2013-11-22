use Irssi qw( signal_add print signal_emit settings_add_str settings_get_str get_irssi_dir );
use strict;
use warnings;
use File::Slurp qw( read_file write_file append_file);

signal_add('bofh','say_bofh');
my $excuses = get_irssi_dir() . '/scripts/datafiles/excuses';
my $buf = eval { read_file ($excuses, array_ref => 1) };
return unless (defined($buf));

sub say_bofh {
  my ($server, $chan) = @_;
  my $excuse = $$buf[int(rand(@$buf))];
  sayit($server, $chan, "[BOFH] $excuse") if (defined($excuse));
}

sub sayit {
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}



