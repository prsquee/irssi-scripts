#dolar2.pl
#http://www.eldolarblue.net/getDolarBlue.php?as=json
#http://www.eldolarblue.net/getDolarLibre.php?as=json

use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use LWP::UserAgent;
use strict;
use warnings;
use Data::Dumper;
use JSON;
use POSIX qw( strftime );

#{{{ init and stuff

my $libreC;
my $libreV;
my $blueC;
my $blueV;
my $dateFetched;

my $blueURL   = qw( http://www.eldolarblue.net/getDolarBlue.php?as=json );
my $libreURL  = qw( http://www.eldolarblue.net/getDolarLibre.php?as=json );

sub init {
  #initial fetch and they'll stay in ram
  ($blueC, $blueV) = gimmeMoney($blueURL);
  ($libreC, $libreV) = gimmeMoney($libreURL);
  #print (CRAP "blues $blueC and $blueV");
  #print (CRAP "libres $libreC and $libreV");

  $dateFetched = strftime "%F", localtime if ($libreC and $libreV and $blueC and $blueV);
  #TODO: get the date from json
}
#}}}

#{{{ do_dolar
sub do_dolar {
	my ($server,$chan,$text) = @_;
  my ($ask, $howmuch) = $text =~ /^!(\w+)\s*(\d*)$/;
  if ($ask eq 'pesos' and not $howmuch) {
    sayit($server, $chan, "!pesos <CANTIDAD>");
		return;
  }
  init() if ($dateFetched ne strftime("%F",localtime));

  my $output = "[Oficial] => $libreC/$libreV | [Blue] => $blueC/$blueV";

	if ($ask eq 'dolar' and not $howmuch) {
		sayit($server, $chan, $output);
		return;
	}
	if ($ask eq 'dolar' and $howmuch > 0) {
		#print_msg("calcular el dolar en pesos");
		my $stinkyPesos = "[Oficial] " . eval("$howmuch * $libreC")  . " pesos" . " | [Tarjeta] " . sprintf("%.2f", eval("$howmuch * $libreC * 1.20")) . " pesos" . " | [Blue] " . eval($howmuch * $blueC) . " pesos";
		sayit($server, $chan, $stinkyPesos) if ($stinkyPesos and !$@);
		return;
	}
	if ($ask eq 'pesos' and $howmuch) {
		my $dollars     = sprintf("%.2f", eval("$howmuch / $libreV"));
	  my $blueDollars = sprintf("%.2f", eval("$howmuch / $blueV" ));
	  my $tarjeta     = sprintf("%.2f", eval("$howmuch / $blueV " ));
		sayit($server, $chan, "[Oficial] $dollars | [Blue] $blueDollars") if ($dollars and $blueDollars and !$@);
		return;
	}
}
#}}}

#{{{  fetch prices
sub gimmeMoney {
  my $url = shift;
	my $ua = new LWP::UserAgent;

  $ua->agent(Irssi::settings_get_str('myUserAgent'));
	$ua->max_redirect(1);
	$ua->timeout(10);

	my $req = $ua->get($url);
  my $result = $req->content;
  #print (CRAP $result);
  my ($compra, $venta) = $result =~ m{buy:(\d\.\d{4}),sell:(\d\.\d{4})};
  return ($compra, $venta);
}#}}}
#{{{ signal and stuff
sub sayit {
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}
signal_add("showme the money","do_dolar");
#}}}
init();
