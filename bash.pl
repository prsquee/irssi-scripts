#bash.org
use Irssi qw (signal_add signal_emit print settings_get_str );
use warnings;
use strict;
use Data::Dumper;
use WWW::BashOrg;

sub fetch_bash {
  my ($server, $chan, $text) = @_;
  #print (CRAP "got this $text");
  my $bash = WWW::BashOrg->new;
  if ($text =~ /^!bash (\d+)/) {
    $bash->get_quote($1) or return;
  } else { $bash->random or return; }

  if ($bash =~ /\r/) {
    my @lines = split ('\r', $bash);
    sayit($server, $chan, $_) foreach (@lines);
  } else { sayit ($server, $chan, $bash); }
}

sub sayit { my $s = shift; $s->command("MSG @_"); }
signal_add("bash quotes", "fetch_bash"); 
