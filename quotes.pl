#quotes.pl
use Irssi;
use strict;

our $friends = ":sQuEE`:sQuEE:F:Fenix:BodyG:KNiXEUR:BigK:KSlappy:SaMRoX:ElPirania:broz;";
our $qfile = "/home/squee/.irssi/scripts/quotes.txt";

sub msg_pub {
	my ($server, $text, $nick, $mask, $chan) = @_;
	return if $server->{tag} !~ /3dg|fnode|lia/;
	return if $text !~ /^!q/;
	
	CASE: {
		if ( $text =~ /^!q(?:uote)?$/) { 
			randq($server, $chan); last CASE; 
		}
		if ( $text =~ /^!qadd\b/ and $friends =~ /:$nick:/ ) {
			add_quote($text,$server,$chan,$nick); last CASE;
		}
		if ( $text =~ /^!qs\b/) { 
			search_quote($text,$server,$chan); last CASE; 
		}
		if ( $text =~ /^!qdel\b/) {
			delete_quote($text,$server,$chan) if $friends =~ /:$nick:/i; last CASE; 
		}
		if ( $text =~ /^!qlast (\d+)?$/ ) {
			last_quotes($text,$server,$chan); last CASE;
		}
		if ( $text =~ /^!qtotal\b/ ) {
			my @buf = open_quotes();
			my $total = $#buf + 1 ;
			$server->command("msg $chan total quotes: $total");
			last CASE;
		}
	}
}


sub last_quotes {
	my ($text,$server,$chan) = @_;
	#open; read the last \d lines , msg and close, GO
	my @buf = open_quotes();
	@buf = reverse(@buf);
	my $c; 
	if ($text =~ /^!qlast$/) {
		$c = 1;
	} else { ($c) = $text =~ /^!qlast (\d+)/; }
	
#	if ($c > $#buf) { 
#		$server->command("msg $chan $c is over 9000!");
#		return;
#	}
	if ($c and @buf) { 
		$server->command("msg $chan [last $c] $buf[$c-1]");
	}
}
sub delete_quote { 
	my ($text,$server,$chan) = @_;
	if ($text eq '!qdel') {
		$server->command("msg $chan pone una parte del quote y lo borro");
		return;
	}

	my ($deleteme) = $text =~ /^!qdel\s(.*)/;
	$deleteme =~ s/\W/\\W/g;

	my @buf = open_quotes();
	my $found = 1;
	my @toBeDeleted; 

	eval { @toBeDeleted = grep { /$deleteme/i } @buf; };

	if ( @toBeDeleted ) {
		if ( $#toBeDeleted == 0 ) {
			@buf = grep { !/($deleteme)/i } @buf;
			open FH, ">$qfile" or die;
			print FH @buf; 
			close (FH) or die;
			$server->command("msg $chan $_ >> deleted!") for (@toBeDeleted);
		} else { $server->command("msg $chan chill dude, tas borrando mas de un quote!");}	
	}
	else { $server->command("msg $chan no encontre nada para borrar"); }
}

sub search_quote {
	my ($text,$server,$chan) = @_;
	if ($text eq '!qs') {
		$server->command("msg $chan que busco??");
		return;
	}
	my ($searchme) = $text =~ /^!qs\s(.*)/;
	#my @buf = open_quotes();
	
	my @words2search = split(" ", $searchme);
	my $bingo = 0;
	my @found = open_quotes();
	#my @found = @buf;
	
	foreach my $n (0 .. $#words2search) {
		eval { 
			@found = grep { /.*?($words2search[$n]).*?/i } @found; 
		} and $bingo = 1; #sacar este bingo y usar $@?
	} unless ($bingo) { 
		$server->command("msg $chan no encontre nada :|"); 
		return;
	  } else {
		  if ($#found <= 4) { 
			  $server->command("msg $chan [quote] $_") for (@found); 
		  } else {
			#tiro 6 quotes randoM sin repetir, AGRANDAR el if de arriba too, or TENCHUBUG!
			my @randnum;
			my $max = 5;
			my $n;
			push @randnum, int(rand(@found));
			#elegir 6 numeros random y sin repetir, overkill? maybe, but it wroks;
			NEW: for (1 .. $max) {
				$n = int(rand(@found));
				for (0 .. $#randnum) {
					redo NEW if ($n == $randnum[$_]);
				}
				push @randnum, $n;
			}
			my $i = ++$max; my $j = ++$#found;
			$server->command("msg $chan $i random quotes de los $j encontrados");
			$server->command("msg $chan [quote] $found[$_]") for (@randnum);
		}
	}
}
	
sub randq {
	my ($server,$chan) = @_;
	my @buf = open_quotes();
	my $q = $buf[int(rand(@buf))];
	$server->command("msg $chan [quote] $q");
}

sub add_quote {
	my ($text,$server,$chan,$nick) = @_;
	if ($text eq '!qadd') {
		$server->command("msg $chan que agrego??");
		return;
	}
	$text =~ s/^!qadd\s//;
	$text = strip_all($text);
	eval {
		open (QAPPND, ">>$qfile") or die ;
		print QAPPND "$text\n"; 
		close (QAPPND) or die;
	} and $server->command("msg $chan agregado");
}

sub strip_all {
	        my ($text) = @_;
		$text =~ s/\x03\d{0,2}(,\d{0,2})?//g;           #mirc colors
		$text =~ s/\x1b\[\d+(?:,\d+)?m//g;              #ansi colors 
		$text =~ s/\x02|\x16|\x1F|\x0F//g;              #bold, inverse, underline and clear
		$text =~ s/^\s+//g;				#espacios vacios al ppio
		return $text;
}

sub open_quotes { 
	open (LOG, "$qfile") or die;
	my @buf = <LOG>;
	close (LOG) or die;
	return @buf;
}
sub print_msg { Irssi::active_win()->print("@_"); }
Irssi::signal_add("message public","msg_pub");
