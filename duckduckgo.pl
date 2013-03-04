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
  my $json_text = $json->allow_nonref->utf8->decode($content);
  #print (CRAP Dumper($json_text));
  sayit($server,$chan,"[Answer] $json_text->{'Answer'}")      if ($json_text->{'Answer'});
  sayit($server,$chan,"[def] $json_text->{'Definition'}")     if ($json_text->{'Definition'});
  sayit($server,$chan,"[Abstract] $json_text->{'Abstract'}")  if ($json_text->{'Abstract'});
  return;
  #sayit($server,$chan,"$time - $title - $desc - Uploaded by $user");
  #signal_emit('write to file',"<sQ`>[$time] - $title\n");
}

sub sayit {
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}
signal_add("cuac cuac go","cuac_cuac");
