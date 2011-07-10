#replace.pl
use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use warnings;


my %lastline;
sub msg_pub { 
	my ($server,$text,$nick,$mask,$chan) = @_;
	return if ($server->{tag} !~ /3dg|fnode|lia|gsg/);
	return if ($text =~ /^!/);
	if ($text =~ m{^s/([^/]+)/([^/]*)/(?:\s+\@(\w+)\s*)?}) {
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
			} 
			else {
				$nickToFind = $nick . $server->{tag};
			}

			my $replaced = $lastline{$nickToFind};
			return if (!$replaced);
			if ($replaced =~ s/$search/$replace/ig) {
				if (!$user) {
					sayit($server,$chan,"FTFY: $replaced");
				} 
				else {
					sayit($server,$chan,"$user quiso decir: $replaced");
				}
			}
		}
		
	} 
	else {
		#si no es s///, guardar la linea
		my $nickk = $nick . $server->{tag};
		$lastline{$nickk} = $text;
	}
}
sub sayit { 
        my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}                                         
sub doit {
        my ($server, $target, $msg) = @_;
	$server->command("ACTION $target $msg");
}
sub printmsg { active_win()->print("@_"); }
Irssi::signal_add("message public","msg_pub");
