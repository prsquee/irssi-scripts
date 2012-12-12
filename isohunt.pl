#isohunt
use Irssi qw(settings_get_str signal_add print);
use warnings;
use strict;
use Data::Dumper;
use LWP::UserAgent;
use JSON;
use Data::Dump;

sub do_ihq {
	my ($server,$chan,$text) = @_;
	my ($searchme) = $text =~ /^!ihq (\w.*)$/;
	if (!$searchme) {
		sayit($server,$chan,"que busco en isohunt?");
		return;
	} 
	#escaping all the spacessssss;
	$searchme =~ s/\s+/%20/;
	my $query = 'http://isohunt.com/js/json.php?ihq=' . $searchme . '&sort=seeds' . '&rows=6';

	my $ua = new LWP::UserAgent;
  $ua->agent(settings_get_str('myUserAgent'));
	$ua->timeout( 10 );

	my $got = $ua->get( $query );
	my $content = $got->decoded_content;
	my $json = new JSON;
	my $json_text = $json->allow_nonref->utf8->relaxed->decode($content);

	foreach my $result ( @{$json_text->{items}->{list}} ) {
		my $title = $result->{title};
		$title =~ s/<\/?b>/\x02/g;  #making it a feature! (?)
		my $SL = 'S/L: ' . $result->{Seeds} . '/' . $result->{leechers} ;
		my $cat = $result->{category};
    my $torrentLink = $result->{enclosure_url};
    #can we short?
    my $short_ref = scalar('Irssi::Script::ggl')->can('do_shortme');
    my $shorten = $short_ref->($torrentLink) if (defined($short_ref) and ref($short_ref) eq 'CODE');
		sayit($server,$chan,"[isohunt] $title - $SL - $cat - $shorten");
	}
}
sub sayit {
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}
signal_add("search isohunt","do_ihq");
