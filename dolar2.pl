#dolar2.pl
use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use LWP::UserAgent;
use strict;
sub msg_pub {
	my($server, $text, $nick, $mask,$chan) = @_;
	do_dolar($text, $chan, $server) if ($server->{tag} =~ /3dg|fnode|lia|gsg/ and $text =~ /^!(dolar|pesos)( \d+)?$/);
	#do_dolar($text, $chan, $server) if ($server->{tag} =~ /3dg|fnode|lia|gsg/ and $text =~ /^!pesos \d+$/);
}

sub do_dolar {
	my ($text, $chan, $server) = @_;
	my $ua = new LWP::UserAgent;
	$ua->agent("AgentName/0.1 " . $ua->agent);
	$ua->max_redirect(4);
	$ua->timeout(40);
    my $url = "http://www.cotizacion-dolar.com.ar";
	my $content;
	my $response = $ua->get( $url );
	if ($response->is_success) {
		$content = $response->decoded_content;
	} else {
		sayit($server, $chan, "me parece q no anda $url"); 
		return;
	}
	#$content =~ s/<[^>]*>/ /gs;
	$content =~ s/<(?:[^>'"]*|(['"]).*?\1)*>/ /gs;
	$content =~ s/<\/(?:[^>'"]*|(['"]).*?\1)*>/ /gs;
	$content =~ s/google_*//g;
	$content =~ s/&nbsp;//g;
	$content =~ s/\s+/ /g;
    #print ("$content");
    #return;
    # Compra Venta Dolar 4.78 4.83 Euro 6.11 6.28

	my ($compra, $venta) = $content =~ /\bDolar\b\s(\d.\d\d)\s(\d\.\d\d)/;
	my ($eucompra, $euventa) = $content =~ /Euro\s(\d\.\d\d)\s(\d\.\d\d)/;
		
    unless ($compra and $venta) {
        sayit($server, $chan, "no encontre los precios D:");
		return;
	}
	my $dolar = "[Dolar] COMPRA => $compra | VENTA => $venta";
	my $euro = "[Euuro] COMPRA => $eucompra | VENTA => $euventa";

    #blueish
    #
    my $blueurl = "http://www.preciodolarblue.com.ar";

    # # # 
	#ok ya tnemos todos los precios, que pidio?

	my ($cmd, $howmuch) = $text =~ /^!(\w+) (\d+)$/;
	# =.= do. not. compute.
	if ($cmd == 'dolar' and not $howmuch) {
		#solo tiro los precios de dolar euro
		sayit($server, $chan, $dolar);
		sayit($server, $chan, $euro);
		return;
	}
	if ($cmd eq 'dolar' and $howmuch) {
		#print_msg("calcular el dolar en pesos");
		my $res = eval("$howmuch * $venta")  . " pesos";
		sayit($server, $chan, $res) if ($res and !$@);
		return;
	}
	if ($cmd eq 'pesos' and $howmuch) {
		#print_msg("calcular esa cantidad de pesos en dolares");
		my $res = eval("$howmuch / $compra");
		$res = sprintf("%.2f",$res) . " dolares";
		sayit($server, $chan, $res) if ($res and !$@);
		return;
	}
}
sub sayit {
        my ($server, $target, $msg) = @_;
        $server->command("MSG $target $msg");
}
sub print_msg { active_win()->print("@_"); }
signal_add("message public","msg_pub");
