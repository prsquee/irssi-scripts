#the pirate bay search
#http://apify.heroku.com/resources/509769d37e208b0002000003

use Irssi qw (signal_add print settings_get_str signal_emit);
use strict;
use warnings;
use 5.014;
use LWP::UserAgent;
use Data::Dumper;
use JSON;

signal_add('arrr','pirate_search');
my $json = new JSON;
my $ua = new LWP::UserAgent;

my $mgnet = 'http://mgnet.me/api/create?format=json&m=';

$ua->agent(settings_get_str('myUserAgent'));
$ua->timeout(10);

sub pirate_search {
  my ($server,$chan,$text) = @_;
  
  my ($booty) = $text =~ /!tpb\s+(.*)$/;
  if (not $booty) {
    sayit($server,$chan,"Ahoy, Matey!");
    return;
  }
  
  my $url = "http://apify.heroku.com/api/tpb.json?sort=seeders&word=$booty";
  my $req = $ua->get($url);
  my $r = $json->utf8->decode($req->content);

  if (scalar @{$r} == 0) {
    sayit ($server,$chan,"avast ye! thar be nothin'");
    return;
  }

  my $showme = 4; 
  my $count = 0;
  my $short_ref = scalar('Irssi::Script::ggl')->can('do_shortme');
  my $shorten = '';

  foreach my $treaye (@$r) {
    last if ($count eq $showme);
    if (defined($treaye->{title}) && $treaye->{seeders} > 0) {
      if ($treaye->{data} =~ m{^//torrents}) {
        my $torrentLink = 'http:' . $treaye->{data};
        $shorten = $short_ref->($torrentLink) if (defined($short_ref) and ref($short_ref) eq 'CODE');
      } elsif ($treaye->{data} =~ /^magnet/) {
        my $mgnetURL = $mgnet . $treaye->{data};
        my $req = $ua->get($mgnetURL);
        my $res = $json->decode($req->content);
        $shorten = $res->{shorturl} if ($res->{state} eq 'success');
      }
      my @desc = split (/, /,$treaye->{desc});
      my $out = "[TPB] $treaye->{title} - S/L: $treaye->{seeders}/$treaye->{leechers} - $desc[0] - $desc[1] - $shorten";
      sayit($server,$chan,$out);
      $count++;
    }
  }
  $booty =~ s/ +/+/g;
  my $fullSearch = "http://thepiratebay.se/search/$booty/0/7/0";
  sayit($server,$chan,"Full Search: $fullSearch");
  return;
}

sub sayit {
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}
