use Irssi;
#use warnings;
use strict;
use Data::Dumper;

my $delims = q(/|!@#$:;);
my $regex = qr{(?x-sm:
    ^!re
    \s+
    "([^"]+)"           #our string and thingy is $1
    \s+
    ([$delims])         #this will be \2
    ( (?:(?!\2).)+ )    #at least one char that is not our delims this is $3
    \2                  #closing delims 
    ([a-z]*)?            #mods, $4
    $                   #EOL
)};





sub pub_msg {
  my ($server,$text,$nick,$mask,$chan) = @_;
  return if ($server->{tag} !~ /fnode/);
  sayit($server, $chan,"broken and not safe!") if ($text eq "!re");

  #if ($text =~ m{!re "([^"]+)" /([^/]+)/$}) {
  if ($text =~ $regex) {
    my $string2match = $1;
    my $regex = $3;
    my $mods = $4 || 'gi';        #TODO I just lost interest

    if ($string2match and $regex) {
      use re 'eval';
      eval { my $test = qr/$regex/};
      sayit($server,$chan,"your regex is bad, and you should feel bad") if ($@);
      return;
    }
    my @matches;
    eval { @matches = $string2match =~ /\Q$regex\E/ig ; };
    #print(CRAP Dumper(@matches));
    if (! $@ and scalar(@matches) > 0) {
      my $matched = join(":", @matches);
      sayit($server,$chan, "MATCH: [$matched]");
    } else {
      sayit($server,$chan, "no match");
    }
  }
}

sub sayit { 
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}
sub print_msg { Irssi::print("@_"); }
Irssi::signal_add("message public","pub_msg");
