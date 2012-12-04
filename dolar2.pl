#dolar2.pl
#TODO: save the prices. do a lastcheck

use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use LWP::UserAgent;
use strict;
use POSIX qw( strftime );

#{{{ init and stuff

my $dolarC;
my $dolarV;
my $blueC;
my $blueV;
my $euroC;
my $euroV;
my $fetched;

sub init {
  ($blueC, $blueV) = getBlue(do_fetch("http://www.preciodolarblue.com.ar"));
  ($dolarC, $dolarV, $euroC, $euroV) = getDollar(do_fetch("http://www.cotizacion-dolar.com.ar"));

  if ($dolarC and $dolarV and $euroC and $euroV and $blueC and $blueV) {
    $fetched = strftime "%F", localtime;
    #print (CRAP $fetched);
  }
}
#}}}
sub msg_pub {
	my($server, $text, $nick, $mask,$chan) = @_;
	do_dolar($text, $chan, $server) if ($server->{tag} =~ /3dg|fnode|lia|gsg/ and $text =~ /^!(?:dolar|pesos)(?:\s+\d+)?$/);
}

sub do_dolar {
	my ($text, $chan, $server) = @_;
	my ($ask, $howmuch) = $text =~ /^!(\w+)\s*(\d*)$/;
  if ($ask eq 'pesos' and not $howmuch) {
    sayit($server, $chan, "!pesos <CANTIDAD>");
		return;
  }
  init() if ($fetched ne strftime("%F",localtime));

  unless (($dolarC and $dolarV) or ($blueC and $blueV)) {
    sayit($server, $chan, "no encontre los precios. check the sauces!");
		return;
	}
	my $output = "[Dolar Oficial] => $dolarC/$dolarV | [Dolar Blue] => $blueC/$blueV | [Euro] => $euroC/$euroV";

	if ($ask eq 'dolar' and not $howmuch) {
		sayit($server, $chan, $output);
		return;
	}
	if ($ask eq 'dolar' and $howmuch > 0) {
		#print_msg("calcular el dolar en pesos");
		my $stinkyPesos = "[Oficial] " . eval("$howmuch * $dolarC")  . " pesos" . " | [Tarjeta] " . eval("$howmuch * 1.15") . " pesos" . "| [Blue] " . eval($howmuch * $blueC) . " pesos";
		sayit($server, $chan, $stinkyPesos) if ($stinkyPesos and !$@);
		return;
	}
	if ($ask eq 'pesos' and $howmuch) {
		#print_msg("calcular esa cantidad de pesos en dolares");
		my $dollars     = sprintf("%.2f", eval("$howmuch / $dolarV"));
		my $blueDollars = sprintf("%.2f", eval("$howmuch / $blueV" ));
    my $euros       = sprintf("%.2f", eval("$howmuch / $euroV" ));
		sayit($server, $chan, "[Dolar Oficial] $dollars | [Dolar Blue] $blueDollars | [Euro] $euros") if ($dollars and $blueDollars and $euros and !$@);
		return;
	}
}

#{{{ get stuff 
sub getDollar  {
  my $content = shift;
	my ($dCompra, $dVenta) = $content =~ /\bDolar\b\s(\d.\d\d)\s(\d\.\d\d)/;
	my ($eCompra, $eVenta) = $content =~ /Euro\s(\d\.\d\d)\s(\d\.\d\d)/;
  return ($dCompra, $dVenta, $eCompra, $eVenta) if ($dCompra and $dVenta and $eCompra and $eVenta );
}

sub getBlue {
  my $content = shift;
  my ($compra, $venta) = $content =~ /\bCompra: Venta: (\d\.\d\d) (\d\.\d\d)\b/;
  return ($compra, $venta) if ($compra and $venta);

}#}}}
#{{{  fetch prices
sub do_fetch {
  my $fetchme = shift;
	my $ua = new LWP::UserAgent;
  $ua->agent(Irssi::settings_get_str('myUserAgent'));
	$ua->max_redirect(2);
	$ua->timeout(20);
	my $content;
	my $response = $ua->get( $fetchme );
  if ($response->is_success) {
		$content = $response->decoded_content;
  } else {
  print_msg("me parece q no anda $fetchme");
	return;
  }
	#$content =~ s/<[^>]*>/ /gs;
	$content =~ s/<(?:[^>'"]*|(['"]).*?\1)*>/ /gs;
	$content =~ s/<\/(?:[^>'"]*|(['"]).*?\1)*>/ /gs;
	$content =~ s/google_*//g;
	$content =~ s/&nbsp;//g;
	$content =~ s/\s+/ /g;
    #print ("$content");
  return $content;
}#}}}
#{{{ signal and stuff
sub sayit {
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}
sub print_msg { active_win()->print("@_"); }
signal_add("message public","msg_pub");
#}}}

init();
