#bitcoins ❤
#https://en.bitcoin.it/wiki/MtGox/API/HTTP/v2

use Irssi qw(signal_add print settings_get_str) ;
use strict;
use warnings;

use JSON;
use Time::HiRes   qw(gettimeofday);
use MIME::Base64  qw(encode_base64 decode_base64);
use Digest::SHA   qw(hmac_sha512);
use LWP::UserAgent;
use Data::Dumper;
 

signal_add('gold digger','bitcoins');

#my $json = JSON->new->allow_nonref;
#my $ua = LWP::UserAgent->new;
#$ua->agent(settings_get_str('myUserAgent'));
# 
#my $apikey = settings_get_str('mtgox_api');
#my $secret = settings_get_str('mtgox_secret');
#
#
#sub getBTCPrice {
#  my ($server,$chan) = @_;
#  my $req = genReq('/2/BTCUSD/money/ticker');
#  my $res = $ua->request($req);
# 
#  if ($res->is_success) {
#    my $btc = $json->utf8->decode($res->decoded_content);
#    print (CRAP Dumper($btc));
#  }
#  else { print (CRAP $res->status_line); }
#  return;
#}
# 
#sub genReq {
#  my ($uri) = shift;
#  my $req = HTTP::Request->new(POST => 'https://data.mtgox.com/api/'.$uri);
#  $req->content_type('application/x-www-form-urlencoded');
#  $req->content("nonce=".microtime());
#  $req->header('Rest-Key'  => $apikey);
#  $req->header('Rest-Sign' => signReq($req->content(),$secret));
#  return $req;
#}
# 
#sub signReq {
#  my ($content,$secret) = @_;
#  return encode_base64(hmac_sha512($content,decode_base64($secret)));
#}
# 
#sub microtime { return sprintf "%d%06d", gettimeofday; }
#
#END
my $json = new JSON;
my $ua = new LWP::UserAgent;

$ua->agent(settings_get_str('myUserAgent'));
$ua->timeout(15);
my $out = undef;
my $last_fetch = time();
my $url = 'https://data.mtgox.com/api/2/BTCUSD/money/ticker';
my $msg = getPrice();

sub bitcoins {
  my ($server,$chan) = @_;
  $msg = getPrice() if (time - $last_fetch > 60);
  sayit ($server,$chan,$msg) if (defined($msg));
  return;
}

sub getPrice {
  my $req = $ua->get($url);
  my $r = $json->utf8->decode($req->decoded_content);
  #print (CRAP Dumper($r));
  if ($r->{result} eq 'success') {
    $out  = '[sell] '     . $r->{data}{sell}{display_short} .'| ';
    $out .= '[buy] '      . $r->{data}{buy}{display_short}  .'| ';
    $out .= '[highest] '  . $r->{data}{high}{display_short} .'| ';
    $out .= '[average] '  . $r->{data}{avg}{display_short};
    $last_fetch = time();
    return $out;
  }
}

sub sayit {
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}

