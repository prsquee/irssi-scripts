#quotes.pl
use Irssi qw( settings_add_str settings_get_str );
use strict;


sub msg_pub {
	my ($server, $text, $nick, $mask, $chan) = @_;
	return if $server->{tag} !~ /3dg|fnode|lia/;
	return if $text !~ /^!q/;
	
	my $qfile = settings_get_str("qfile");
	my $fwends = settings_get_str("fwends");
	CASE: {
		if ( $text =~ /^!q(?:uote)?$/) { randq($server, $chan,$qfile); last CASE; }
		if ( $text =~ /^!qadd\b/ and $fwends =~ /:$nick:/ ) { add_quote($text,$server,$chan,$nick,$qfile); last CASE; }
		if ( $text =~ /^!qs\b/) { search_quote($text,$server,$chan,$qfile); last CASE; }
		if ( $text =~ /^!qdel\b/) { delete_quote($text,$server,$chan,$qfile) if $fwends =~ /:$nick:/i; last CASE; }
		if ( $text =~ /^!qlast (\d+)?$/ ) { last_quotes($text,$server,$chan,$qfile); last CASE; }
		if ( $text =~ /^!qtotal\b/ ) {
			my @buf = openq($qfile);
			my $total = $#buf + 1 ;
			$server->command("msg $chan total quotes: $total");
			last CASE;
		}
	}
}


sub last_quotes {
	my ($text,$server,$chan,$qfile) = @_;
	#open; read the last \d lines , msg and close, GO
	my @buf = openq($qfile);
	my ($c) = $text =~ /^!qlast\s+(\d+)/;
	if ($c > $#buf) {
		sayit($server,$chan,"you can't handle that much truth");
		return;
	}
	sayit($server,$chan,"[last $c] $buf[-${c}]") if ($c and @buf);
}
sub delete_quote { 
	my ($text,$server,$chan,$qfile) = @_;
	if ($text eq '!qdel') {
		$server->command("msg $chan pone una parte del quote y lo borro");
		return;
	}

	my ($deleteme) = $text =~ /^!qdel\s(.*)/;
	$deleteme =~ s/\W/\\W/g;

	my @buf = openq($qfile);
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
	my ($text,$server,$chan,$qfile) = @_;
	if ($text eq '!qs') {
		$server->command("msg $chan que busco??");
		return;
	}
	my ($searchme) = $text =~ /^!qs\s(.*)/;
	
	my @words2search = split(" ", $searchme);
	my $bingo = 0;
	my @found = openq($qfile);
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
	my ($server,$chan,$qfile) = @_;
	my @buf = openq($qfile);
	my $q = $buf[int(rand(@buf))];
	sayit($server,$chan,"[rand] $q");
}

sub add_quote {
	my ($text,$server,$chan,$nick,$qfile) = @_;
	if ($text eq '!qadd') {
		sait($server,$chan,"que agrego??");
		return;
	}
	$text =~ s/^!qadd\s//;
	$text = strip_all($text);
	eval {
		open QAPPND, ">>$qfile" or die ;
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

sub openq { 
	my ($qfile) = @_;
	open LOG, "$qfile" or die "$@";
	my @buf = <LOG>;
	close (LOG) or die;
	return @buf;
}
sub print_msg { Irssi::active_win()->print("@_"); }
sub sayit {
        my ($server, $target, $msg) = @_;
        $server->command("MSG $target $msg");
}
Irssi::signal_add("message public","msg_pub");
Irssi::settings_add_str("quotes", "qfile", '');
Irssi::settings_add_str("quotes", "fwends", '');
