use Irssi;
use strict;
use warnings;

our %lastline;

sub msg_pub { 
	my ($server,$text,$nick,$mask,$chan) = @_;
	return if ($server->{tag} !~ /3dg|fnode|lia|gsg/);
	if ($text =~ m{^s/([^/]+)/([^/]*)/(?:\s+\@(\w+)\s*)?$}) {
		#search and replace detected:
		my $search;
		use re 'eval';
	       	eval { $search = qr/$1/i };
		if ($@) { $server->command("MSG $chan l2regex dude"); return; }

		my $replace = $2;
		my $user = $3;
		my $nickToFind;
		if ($search) {
			
			if ($user) { 
				$nickToFind = $user . $server->{tag}; 
			} else {
				$nickToFind = $nick . $server->{tag};
			}

			my $replaced = $lastline{$nickToFind};
			if ($replaced =~ s/$search/$replace/ig) {
				if (!$user) {
					$server->command("MSG $chan FTFY: $replaced");
				} else {
					$server->command("ACTION $chan fixed that for $nick, $user quiso decir: $replaced");
				}
			}
		}
		
	} else {

		#si no es s//, guardar la linea
		my $nickk = $nick . $server->{tag};
		$lastline{$nickk} = $text;
	}
}


Irssi::signal_add("message public","msg_pub");
#Irssi::signal_add("message own_public","msg_pub");
