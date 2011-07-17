#calc.pl
use strict;
use Irssi qw( active_win signal_add print server_find_tag );

sub msg_pub {
	my ($server, $msg, $nick, $mask, $chan) = @_;
	if ($server->{tag} =~ /3dg|fnode|lia|gsg/ and $msg =~ /^!calc/) {
		for ($msg) {
			s/,/./g; 
			s/[^*.+0-9&|)(x\/^-]//g; 		# remove anything that is not a math symbol
			s/\*\*/^/g;				# teh powah!
			s/([*+\\.\/x-])\1*/$1/g;		# borrar simbolos repetidos
			s/\^/**/g;
			s/(?<!0)x//g;
		}
		my $answer = eval("($msg) || 0");
			
		if ($@) {
			$msg = "INSUFFICIENT DATA FOR A MEANINGFUL ANSWER"; #ERROR (${\ (split / at/, $@, 2)[0]}) ;
		} 
		else {
			$msg = $answer;
		}
		sayit($server,$chan,$msg); 
	}	
}
sub sayit { 
	my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}   
signal_add("message public","msg_pub");


