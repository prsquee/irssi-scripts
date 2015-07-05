#replace.pl
use Irssi qw( command_bind signal_add signal_emit print settings_get_str );
use warnings;
use strict;

signal_add('message public','search_and_replace');

my %lastline_of;
my $delimiter = q([/|!@#$%&:;]);
my $regex = qr{(?x-sm:
    ^s
      ($delimiter)      # this is the first match, only used as \1.
        (             # start of the searching pattern. this is \2
          (?:\\.      # here we match a \ followed by any char, such as \w
            |
          (?!\1).)+   # lookahead a char that is not a delimiter
        )             # end of matching \2
      \1              # match another delimiter, closing the search pattern.
        (             # start of the replace pattern, this is \3
          (?:(?!\1).)*   # we match anything that is not same lookahead but optional
        )             # end of matching \3
      \1?             # closing is optional by losing karma.
      (?:\s*\@(\w+))? # this is \4, used when correcting someone else.
)};

my $networks = settings_get_str('active_networks');

sub search_and_replace {
  my ($server, $text, $nick, $mask, $chan) = @_;
  return if ($server->{tag} !~ /$networks/);
  return if ($text =~ /^!/);
  if ($text =~ $regex) {
    my $used_delimiter = $1;
    my $search = undef;
    my $replace = ($3) ? $3 : '';
    my $another_user = ($4) ? $4 : undef;

    use re 'eval';
    eval { $search = qr/$2/; };

    if ($@) {
      sayit($server, $chan, 'your regex is bad and you should feel bad.');
      return;
    }
    my $this_user = ($another_user) ? $another_user . $mask : $nick . $mask;
    my $replaced = $lastline_of{$this_user};
    return if (!$replaced);

    if (not $another_user and $text !~ /$used_delimiter$/) {
      sayit($server, $chan, 'CLOSE YOUR REGEX! 1 karma taken from ' . $nick);
      signal_emit('karma bitch', $nick, '--', $chan . '_' . $server->{tag});
      return;
    }
    if ($replaced =~ s{$search}{$replace}ig) {
      my $result = ($another_user) ? "$another_user quiso decir: $replaced"
                                   : "FTFY: $replaced"
                                   ;

      sayit($server, $chan, $result);
    }

  }
  else {
    #we save every line;
    $lastline_of{$nick . $mask} = $text;
  }
}
sub sayit { my $s = shift; $s->command("MSG @_"); }
