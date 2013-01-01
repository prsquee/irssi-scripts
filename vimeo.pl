#isohunt
use Irssi qw(settings_get_str signal_emit signal_add print);
#use warnings;
use strict;
use Data::Dumper;
use LWP::UserAgent;
use JSON;
use Data::Dump;

my $json = new JSON;
$json = $json->utf8([1]);
my $ua = new LWP::UserAgent;
$ua->agent(settings_get_str('myUserAgent'));
$ua->timeout( 10 );

sub check_vimeo {
	my ($server,$chan,$vid) = @_;
	my $query = "http://vimeo.com/api/v2/video/${vid}.json";

	my $got = $ua->get( $query );
	my $content = $got->decoded_content;
	my $json_text = $json->allow_nonref->utf8->decode($content)->[0];
  #print (CRAP Dumper($json_text));
  my $time = $json_text->{'duration'};
  my $hours = sprintf ("%02d:", $time/3600) if ($time >= 3600);
  $time = $time - 3600 * int($hours) if ($hours);
  my $mins = '00:';
  my $secs;
  if ($time >= 60) {
    $mins = sprintf ("%02d:", $time/60);
    $secs = sprintf ("%02d",  $time%60);
  } elsif ($time < 60) {
    $secs = sprintf("%02d", $time);
  }
  $time = "[${hours}${mins}${secs}]";
  my $user = $json_text->{'user_name'};
  my $title = $json_text->{'title'};
  my $desc = $json_text->{'description'};

  sayit($server,$chan,"[$time] - $title - $desc - Uploaded by $user");
  signal_emit('write to file',"<sQ`>[$time] - $title\n");
}

sub sayit {
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}
signal_add("check vimeo","check_vimeo");
