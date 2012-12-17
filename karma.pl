#karma is a bitch!
use Irssi qw(signal_add print get_irssi_dir ) ;
use warnings;
use strict;
use Data::Dumper;
use Storable qw (store retrieve);

my $karmaStorable = get_irssi_dir() . "/scripts/datafiles/karma.storable";
my $karma = eval { retrieve($karmaStorable) } || [];

sub calc_karma {
	my ($name,$op) = @_;
  $karma->{$name} = 0 if (!exists($karma->{$name}) or !defined($karma->{$name}));
  my $evalme = '$karma->{$name}' . $op;
  eval "$evalme";
  store $karma, $karmaStorable;
}
sub show_karma {
  my ($server,$chan,$name) = @_;
  if (!exists ($karma->{$name}) or !defined($karma->{$name}) or $karma->{$name} == 0) {
    $name =~ s/$server->{tag}$//;
    sayit($server,$chan,"$name has neutral karma");
  }
  elsif (defined($karma->{$name})) {
    my $k = $karma->{$name};
    $name =~ s/$server->{tag}$//;
    sayit($server,$chan,"karma for $name: $k");
  }
}
sub sayit {
  my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}
signal_add('karma check','show_karma');
signal_add('karma bitch','calc_karma');
