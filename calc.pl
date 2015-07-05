#calc.pl
#TODO: add cientific stuff 
use warnings;
use strict;
use Irssi qw( signal_add print );

my $error = 'INSUFFICIENT DATA FOR MEANINGFUL ANSWER';

sub do_calculate {
  my ($server, $chan, $math) = @_;
  $math =~ s/^!calc +//;
  $math =~ s/,/./g;
  $math =~ s/[^*.+0-9&|)(x\/^-]//g;   # remove anything that is not a math symbol
  $math =~ s/\*\*/^/g;                # to teh powah!
  $math =~ s/([*+\\.\/x-])\1*/$1/g;   # borrar simbolos repetidos
  $math =~ s/\^/**/g;                 #TODO arreglar el regex de ariiba
  $math =~ s/(?<!0)x//g;              #stripar hex con lookback
  $math =~ s/^\W+//;                  #leading useless stuff

  my $answer = eval($math);
  #print (CRAP "$answer and $math");
  $answer = $error if (not defined($answer) or $answer eq 'inf');
  sayit($server, $chan, $answer);
}
sub sayit { my $s = shift; $s->command("MSG @_"); }
signal_add("calculate","do_calculate");
