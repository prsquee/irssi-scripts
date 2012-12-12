use Irssi qw( settings_get_str signal_add print ) ;
use LWP::UserAgent;
use strict;
use warnings;
use Data::Dumper;

my $url = 'http://www.smn.gov.ar/layouts/temperatura_layout.php';
my $ua = new LWP::UserAgent;
$ua->agent(settings_get_str('myUserAgent'));
$ua->max_redirect( 2 );
$ua->timeout( 10 );

sub do_temp {
	my ($server, $chan) = @_;
  #my $url = HTTP::Request->new(GET => 'http://www.smn.gov.ar/layouts/temperatura_layout.php');

	my $req = $ua->get( $url );
	if ($req->decoded_content) {
		my $temp = $req->decoded_content;
	  $temp =~ s/\|\w+//;
		sayit($server,$chan,$temp)if ($temp);
		return;
	} else {
      print(CRAP "FAIL!");
	}
}
sub sayit {
	my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}
signal_add("get temp","do_temp");
