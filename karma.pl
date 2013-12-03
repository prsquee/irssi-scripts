#karma is a bitch!
use Irssi qw(signal_add print get_irssi_dir ) ;
use warnings;
use strict;
use Data::Dumper;
use Storable qw (store retrieve);

my $karmaStorable = get_irssi_dir() . "/scripts/datafiles/karma.storable";
our $karma = eval { retrieve($karmaStorable) } || [];

#{{{ calc
sub calc_karma {
	my ($name,$op) = @_;
  $karma->{$name} = 0 if (not exists($karma->{$name}) or not defined($karma->{$name}));
  my $evalme = '$karma->{$name}' . $op;
  eval "$evalme";
  store $karma, $karmaStorable;
}#}}}
#{{{ show
sub show_karma {
  my ($server,$chan,$name) = @_;
  if (not exists ($karma->{$name}) or not defined($karma->{$name}) or $karma->{$name} eq '0') {
    $name =~ s/$server->{tag}$//;
    sayit($server,$chan,"$name has neutral karma");
  }
  elsif (defined($karma->{$name})) {
    my $k = $karma->{$name};
    $name =~ s/$server->{tag}$//;
    sayit($server,$chan,"karma for $name: $k");
  }
}
#}}}
# {{{ set karma
sub set_karma {
	my ($server,$chan,$key,$val) = @_;
	$karma->{$key} = $val;
	store $karma, $karmaStorable;
	show_karma($server,$chan,$key) if (not $@);
}
#}}}
#{{{ # show rank with !rank
sub show_rank {
  my ($server,$chan) = @_;
  my %sortme = (); 
  foreach (keys %$karma) {
    delete $karma->{$_} unless (defined($karma->{$_}));
    $sortme{$_} = $karma->{$_} if ($karma->{$_} =~ /^-?\d+$/)
  }
  my @sorted = sort { $sortme{$a} <=> $sortme{$b} } keys %sortme;
  my $lowest = '';
  my $highest = '';
  for my $i (0..5) {
    $lowest   .= '[' . scalar($sorted[$i] =~ s/$server->{tag}$//r) . ': '."\x02".$karma->{$sorted[$i]}."\x02".'] ';
    my $j = '-' . ++$i;
    $highest  .= '[' . scalar($sorted[$j] =~ s/$server->{tag}$//r) . ': '."\x02".$karma->{$sorted[$j]}."\x02".'] ';
  }
  sayit($server, $chan, $highest);
  sayit($server, $chan, $lowest);
}
#}}}
#{{{ stuff
sub sayit { my $s = shift; $s->command("MSG @_"); }
signal_add('karma check', 'show_karma');
signal_add('karma bitch', 'calc_karma');
signal_add('karma set',	  'set_karma');
signal_add('karma rank',  'show_rank');
#}}}
