#replace.pl
use Irssi qw( command_bind signal_add print settings_get_str ) ;
use warnings;
use strict;

my %lastline_of;
my $delims = q(/|!@#$%&:;);
my $regex = qr{(?x-sm:
    ^s
      ([$delims])
        ( (?:\\.|(?!\1).)+ )
        #matchea \\ and a single char or lookahead un char que no sea un delimiter 
      \1                       #otro delimiter 
        ( (?:\\.|(?!\1).)* )
      \1?                      #cierre opcional
      (?:\s*\@(\w+))?           #optional username
)};
#m{^s([/|@])((?:(?!\1).)+)\1((?:.(?!\1).)*)\1?}) {

my $networks = settings_get_str('active_networks');

sub search_and_replace {
  my ($server, $text, $nick, $mask, $chan) = @_;
  return if ($server->{tag} !~ /$networks/);
  return if ($text =~ /^!/);
  if ($text =~ $regex) {
    my $search = undef;
    my $replace = $3;
    use re 'eval';
    eval { $search = qr/$2/; };
    if ($@) {
      sayit($server, $chan, 'your regex is bad and you should feel bad.');
      return;
    }
    my $another_user = $4 if $4;
    my $this_user = ($another_user) ? $another_user . $mask : $nick . $mask;
    my $replaced = $lastline_of{$this_user};
    return if (!$replaced);

    if ($replaced =~ s{$search}{$replace}ig) {
      my $result = ($another_user) ? "$another_user quiso decir: $replaced"
                                   : "FTFY: $replaced"
                                   ;

      sayit($server, $chan, $result);
    }
  }
  else {
    $lastline_of{$nick . $mask} = $text;
  }
}
sub sayit { my $s = shift; $s->command("MSG @_"); }
Irssi::signal_add('message public','search_and_replace');
