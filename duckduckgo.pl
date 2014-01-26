#isohunt
use Irssi qw(settings_get_str signal_emit signal_add print);
#use warnings;
use strict;
use Data::Dumper;
use LWP::UserAgent;
use JSON;

my $json = new JSON;
$json = $json->utf8([1]);
my $ua = new LWP::UserAgent;
$ua->agent(settings_get_str('myUserAgent'));
$ua->timeout( 10 );

sub cuac_cuac {
	my ($server,$chan,$searchme) = @_;
	my $query = "https://api.duckduckgo.com/?q=${searchme}&format=json";

	my $got = $ua->get( $query );
	my $content = $got->decoded_content;
  my $result = eval { $json->allow_nonref->utf8->decode($content) };
  return if $@;
  #print (CRAP Dumper($result));
  sayit($server,$chan,"[Answer] $result->{'Answer'}")      if ($result->{'Answer'});
  sayit($server,$chan,"[def] $result->{'Definition'}")     if ($result->{'Definition'});
  sayit($server,$chan,"[Abstract] $result->{'Abstract'}")  if ($result->{'Abstract'});
  return;
  #sayit($server,$chan,"$time - $title - $desc - Uploaded by $user");
  #signal_emit('write to file',"<sQ`>[$time] - $title\n");
}

sub sayit {
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}
signal_add("cuac cuac go","cuac_cuac");
