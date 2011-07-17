#imdb api
#http://imdbapi.com/

use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use strict;
use LWP::UserAgent;
use URI::Escape qw( uri_escape );
use Data::Dumper;
use JSON;
sub msg_pub {
	my($server, $text, $nick, $mask,$chan) = @_;
	do_imdb($text, $chan, $server) if ($server->{tag} =~ /3dg|fnode|lia|gsg/ and $text =~ /^!imdb/);
}

sub do_imdb {
	my ($text, $chan, $server) = @_;
	my ($query) = $text =~ /^!imdb\s+(.*)/;
	if (!$query) {
		sayit($server,$chan, "I will tell ya everything about a movie!");
		return;
	} 
	else {
		my $ua = new LWP::UserAgent;
		$ua->timeout(20);
		my $url =  "http://www.imdbapi.com/?t=";
		my $query8 = uri_escape($query);
		my $url2get = $url . $query8;
		my $got = $ua->get($url2get);
		my $content = $got->decoded_content;
		my $json = new JSON;
		my $imdb = $json->allow_nonref->decode($content);
		if ($imdb->{Response} !~ /True/ ) {
			sayit($server,$chan,"sorry, doesn't ring a bell, try again");
			return;
		}
		my $title = "Title: [$imdb->{Title}] - [http://www.imdb.com/title/$imdb->{ID}]";
		my $genre = "Genre: $imdb->{Genre} - Rating: $imdb->{Rating} - Year: $imdb->{Year}";
		my $plot = "Plot: $imdb->{Plot}";
		sayit($server,$chan,$title);
		sayit($server,$chan,$genre);
		sayit($server,$chan,$plot);
		my $a = Dumper($imdb);
		print_msg($a);
		return;
	}
}

sub sayit { 
	my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}                                         
sub print_msg { active_win()->print("@_"); }
signal_add("message public","msg_pub");
