#calc.pl
use warnings;
use strict;
use Irssi qw( signal_add print );


my $error = 'INSUFFICIENT DATA FOR A MEANINGFUL ANSWER';

sub do_calculate {
	my ($server, $chan, $text) = @_;
  #if ($server->{tag} =~ /3dg|fnode|lia|gsg/ and $msg =~ /^!calc/) {
  $text =~ s/^!calc //;
  $text =~ s/,/./g;
  $text =~ s/[^*.+0-9&|)(x\/^-]//g;   # remove anything that is not a math symbol
  $text =~ s/\*\*/^/g;				        # teh powah!
  $text =~ s/([*+\\.\/x-])\1*/$1/g;		# borrar simbolos repetidos
  $text =~ s/\^/**/g;                 #TODO arreglar el regex de ariiba
  $text =~ s/(?<!0)x//g;              #stripar hex con lookback

  my $answer = eval("($text) || 0");
			
  my $out = $@ ? $error : $answer;
  sayit($server,$chan,$out);
}
sub sayit {
	my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}
signal_add("calculate","do_calculate");
