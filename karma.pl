#karma is a bitch!
use Irssi qw( signal_add print get_irssi_dir );
use warnings;
use strict;
use Data::Dumper;
use Storable qw (store retrieve);
use utf8;

signal_add('karma check', 'show_karma');
signal_add('karma bitch', 'calc_karma');
signal_add('karma set',   'set_karma');
signal_add('karma rank',  'show_rank');
signal_add('karma flip',  'flip_karma');

my $karma_storable = get_irssi_dir() . "/scripts/datafiles/karma.storable";

our $karma = eval { retrieve($karma_storable) } || [];

my %novelty = (
  'sQuEE'     => '🍺',
  'sQuEE`'    => '🍺',
  'osx'       => '⌘',
  'OSX'       => '⌘',
  'mac'       => '⌘',
  'macintosh' => '⌘',
  'apple'     => '',
  'iphone'    => '📱',
  'perl'      => '🐫 ',
  'spock'     => '🖖',
);

#{{{ (╯°□°）╯︵ ɐɯɹɐʞ
sub flip_karma {
  my ($server, $chan) = @_;
  my $channel = $chan . '_' . $server->{tag};
  my $this_channel = $karma->{$channel};

  foreach my $thingy (keys %$this_channel) {
    if ($this_channel->{$thingy} =~ /^-\d+$/) {
      $this_channel->{$thingy} = abs($this_channel->{$thingy});
    }
    elsif ($this_channel->{$thingy} =~ /^\d+$/) {
      $this_channel->{$thingy} = '-' . $this_channel->{$thingy};
    }
  }
  store $karma, $karma_storable;
  show_rank($server, $chan);
}
#}}}
#{{{ take one and give one
sub calc_karma {
  my ($thingy, $op, $channel) = @_;

  $karma->{$channel}->{$thingy} = 0
    if (not exists($karma->{$channel}->{$thingy})
        or not defined($karma->{$channel}->{$thingy})
  );
  my $evalme = '$karma->{$channel}->{$thingy}' . $op;
  eval "$evalme";
  store $karma, $karma_storable;
}
#}}}
#{{{ show karma when asked
sub show_karma {
  my ($server, $chan, $thingy) = @_;
  my $channel = $chan . '_' . $server->{tag};

  if (exists($novelty{$thingy})) {
    sayit($server, $chan, 'karma for ' . $thingy . ': ' . $novelty{$thingy});
  }
  elsif (not exists($karma->{$channel}->{$thingy})  or
      not defined($karma->{$channel}->{$thingy}) or
      $karma->{$channel}->{$thingy} == 0) {
    sayit($server, $chan, $thingy . ' has neutral karma.');
  }
  elsif (defined($karma->{$channel}->{$thingy})) {
    sayit(
      $server,
      $chan,
      'karma for ' . $thingy . ': ' . $karma->{$channel}->{$thingy}
    );
  }
}#}}}

#{{{ set karma
sub set_karma {
  my ($server, $chan, $thingy, $new_karma) = @_;
  my $channel = $chan . '_' . $server->{tag};
  $karma->{$channel}->{$thingy} = $new_karma;
  store $karma, $karma_storable;
  show_karma($server, $chan, $thingy) if (not $@);
}
#}}}
# show rank with !rank
sub show_rank {
  my ($server, $chan) = @_;
  my $this_channel = $chan . '_' . $server->{tag};
  my $channel_karma_ref = $karma->{$this_channel};
  my %sortme = ();

  #keys in karma are namesfnode.
  foreach (keys %$channel_karma_ref) {
    next if /^sQ/;
    #now make sure everything in sortme is numerical.
    delete $channel_karma_ref->{$_} unless (defined($channel_karma_ref->{$_}));
    $sortme{$_} = $channel_karma_ref->{$_} if ($channel_karma_ref->{$_} =~ /^-?\d+$/)
  }
  #use the spaceship magic, lowest karma will be the first element.
  my @sorted = sort { $sortme{$a} <=> $sortme{$b} } keys %sortme;

  my $lowest  = '';
  my $highest = '';

  for my $i (0..8) {
    $lowest .= '['
            .   $sorted[$i]
            .   ': '
            .   "\x02"
            .   $channel_karma_ref->{$sorted[$i]}
            .   "\x02"
            .   '] ';

    my $j = '-' . ++$i;

    $highest .= '['
             .   $sorted[$j]
             .   ': '
             .   "\x02"
             .   $channel_karma_ref->{$sorted[$j]}
             .   "\x02"
             .   '] ';
  }
  sayit($server, $chan, $highest);
  sayit($server, $chan, $lowest);
}

#stuff
sub sayit { my $s = shift; $s->command("MSG @_"); }

