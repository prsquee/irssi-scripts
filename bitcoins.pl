#bit
#https://en.bitcoin.it/wiki/MtGox/API/HTTP/v1#HTTP_API_version_1_methods

use Irssi qw (signal_add print settings_get_str signal_emit);
use strict;
use warnings;
use LWP::UserAgent;
use Data::Dumper;
use JSON;

signal_add('gold digger','bitcoin');
my $json = new JSON;
my $ua = new LWP::UserAgent;

$ua->agent(settings_get_str('myUserAgent'));
$ua->timeout(15);

sub bitcoin {
  my ($server,$chan,$mla) = @_;
  my $url = 'https://mtgox.com/api/1/BTCUSD/ticker';
  my $req = $ua->get($url);
  my $r = $json->utf8->decode($req->decoded_content);
	#print (CRAP Dumper($r));
	#return;

	if ($r->{result} eq 'success') {
		my $ret = $r->{return};
		my $out = '[sell] '			. $r->{return}->{sell}->{display_short};
		$out .= ' | [buy] '			. $r->{return}->{buy}->{display_short};
		$out .= ' | [highest] ' . $r->{return}->{high}->{display_short};
		$out .= ' | [lowerst] ' . $r->{return}->{low}->{display_short};
		sayit ($server,$chan,$out);
		return;
	}
#  my $condition = uc $result->{condition};
#  my $price = $result->{price};
#  my $currency = $result->{currency_id};
#  my $howmuch = $currency . ' $' . $price;
#  my $city    = $result->{seller_address}->{city}->{name};
#  my $pais    = $result->{seller_address}->{country}->{id};
#  my $sold    = $result->{sold_quantity};
#
#  my $out = "[$condition] $title - $howmuch - Sold: $sold - $city - $pais";
#  sayit($server,$chan,$out);
#  signal_emit('write to file',"$out\n") if ($chan =~ /sysarmy|moob/);
}

sub sayit {
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}
