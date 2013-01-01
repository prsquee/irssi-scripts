#imdb api http://imdbapi.com/

#$imdb struct
#'ID' => 'tt0290978',
#'Director' => 'N/A',
#'Poster' => 'http://ia.media-imdb.com/images/M/MV5BMTQ2MzAxODI3M15BMl5BanBnXkFtZTcwNTE2MjAwMQ@@._V1._SX320.jpg',
#'Actors' => 'Ricky Gervais, Martin Freeman, Mackenzie Crook, Lucy Davis',
#'Runtime' => '29 mins',
#'Genre' => 'Comedy, Drama',
#'Rating' => '9.2',
#'Released' => '23 Jan 2003',
#'Response' => 'True',
#'Votes' => '16626',
#'Title' => 'The Office',
#'Year' => '2001',
#'Rated' => 'TV-MA',
#'Writer' => 'N/A',
#'Plot' => 'The story of an office that faces closure when the company decides to downsize

use Irssi qw(signal_add print signal_emit) ;
use strict;
use LWP::UserAgent;
use URI::Escape qw( uri_escape );
use Data::Dumper;
use JSON;

my $json = new JSON;
my $ua = new LWP::UserAgent;
$ua->timeout(10);

sub do_imdb {
	my ($server, $chan, $text) = @_;
  #my ($text, $chan, $server) = @_;
	my $param; my $query;

	if ($text =~ /^tt/) {
		$param = 'i';
	} elsif ($text =~ /^!imdb/) {
		$param = 't';
	}
		
	if ($text =~ /^!imdb\s+(.*)/) {
		$query = $1;
		$query = uri_escape($query);
	} elsif ($text =~ /^tt\d+/) {
		$query = $text;
	}
	return if (!$query);
	my $url = "http://www.imdbapi.com/?${param}=${query}" if ($param and $query);
	
	my $got = $ua->get($url);
	my $content = $got->decoded_content;
	my $imdb = $json->allow_nonref->decode($content);
  #print (CRAP Dumper($imdb));
	if ($imdb->{Response} !~ /True/ ) {
		sayit($server,$chan,"not found, try with the full name");
		return;
	}
	my $link;
	if ($text =~ /^!imdb/) {
		$link = "- [http://www.imdb.com/title/$imdb->{ID}]";
	} else {
		$link = '';
	}

	my $title = "Title: [$imdb->{Title}] $link";
	my $genre = "Genre: $imdb->{Genre} - Rating: $imdb->{Rating} - Year: $imdb->{Year}";
	my $plot = "Plot: $imdb->{Plot}";
	sayit($server,$chan,$title);
	sayit($server,$chan,$genre);
	sayit($server,$chan,$plot);
  signal_emit('write to file', "<sQ`> $title\n<sQ`> $genre\n<sQ`> $plot\n") if ($chan =~ /sysarmy|moob/);
	return;
}

sub sayit {
	my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}
signal_add("search imdb","do_imdb");

