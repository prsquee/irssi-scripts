#searchreplace.pl
use Irssi;
use warnings;


sub pub_msg {
	my ($server,$text,$nick,$mask,$chan) = @_ ;
	return if ($server->{tag} !~ /3dg|fnode/);
	$server->command("msg $chan search&replace tester, usage: !sr \"string to test\" s/search/replace/"), return if ($text eq "!sr");

	if ($text =~ m{!sr "([^"]+)" s/([^/]+)/([^/]+)/$}) {
		my $string = $1;
		my $regex = $2;
		my $replace = $3;
		
		if ($string and $regex) {
			print_msg("$1 - $2 - $3");
			
			use re 'eval'; 
			eval { $regex = qr/$2/i }; 
			if ($@) {
				$server->command("msg $chan wrong syntax?"); return;
				#	Irssi::print("$@"); return;
			}
		}

		eval { $string =~ s/$regex/$replace/ };
		if (!$@) {
			$server->command("msg $chan result: $string");
		} else {
			$server->command("msg $chan NOMATCH");
		}
	} else {
		$server->command("msg $chan you are doing it wrong") if ($text =~ /^!re .*$/);
	}
} 


sub print_msg { Irssi::print("@_"); }

Irssi::signal_add("message public","pub_msg");
