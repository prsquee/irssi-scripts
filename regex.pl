use Irssi;
use warnings;


sub pub_msg {
	my ($server,$text,$nick,$mask,$chan) = @_ ;
	return if ($server->{tag} !~ /3dg|fnode/);
	$server->command("msg $chan regex tester, usage: !re \"string to match\" /regex/"), return if ($text eq "!re");

	if ($text =~ m{!re "([^"]+)" /([^/]+)/(\w+)?$}) {
		my $string2match = $1;
		my $regex = $2;
		my $mods = $3 if ($3); 
		my @matches;
		
		if ($string2match and $regex) {
			#print_msg("$1 - $2 - $3");
			
			#	$matchSyntax = $
			use re 'eval'; 
			eval { $regex = qr/$2/i }; 
			if ($@) {
				#$server->command("msg $chan wrong syntax?"); return;
				Irssi::print("$@"); return;
			}
		}

		eval { @matches = $string2match =~ /$regex/g };
		if (!$@ and $#matches >= 0) {
			my $backref = ":";
			$backref .= "$_:" for (@matches);
			$server->command("msg $chan MATCH: [$backref]");
		} else {
			$server->command("msg $chan NOMATCH");
		}
	} else {
		$server->command("msg $chan you are doing it wrong") if ($text =~ /^!re .*$/);
	}
} 


sub print_msg { Irssi::print("@_"); }

Irssi::signal_add("message public","pub_msg");
