#save links to file

use Irssi qw (get_irssi_dir signal_add print settings_get_str);
use strict;
use warnings;
use Data::Dumper;
use File::Slurp qw( read_file write_file append_file);
use POSIX qw( strftime );

signal_add('write to file','write_this_down');
my $dir = get_irssi_dir() . '/scripts/datafiles/catched_links/';

sub write_this_down {
  my $text  = shift;
  my $today = $dir . strftime("%F", localtime) . '.txt';
  eval { write_file( $today, {append => 1, binmode => ':utf8'}, "$text\n") };
  if (!$@) { return 1; }
  else { return undef; }
}
