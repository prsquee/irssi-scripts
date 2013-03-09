#omdb api http://omdbapi.com/

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
  my $param = '';
  my $query = '';

  if ($text =~ /^tt\d+/) {
    $param = 'i';
    $query = $text;
  } elsif ($text =~ /^!imdb\s+(.*)/) {
    $param = 't';
    $query = $1;
    $query = uri_escape($query);
  }
    
  return if (!$query);
  my $url = "http://www.omdbapi.com/?${param}=${query}" if ($param and $query);
  
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
    $link = "- [http://www.imdb.com/title/$imdb->{imdbID}]";
  } else {
    $link = '';
  }

  my $title = "$imdb->{Title} - Directed by $imdb->{Director}";
  my $genre = "Year: $imdb->{Year} - Genre: $imdb->{Genre} - Rating: $imdb->{imdbRating} - Votes: $imdb->{imdbVotes}";
  my $plot  = "Plot: $imdb->{Plot} $link";
  sayit($server,$chan,$title);
  sayit($server,$chan,$genre);
  sayit($server,$chan,$plot);
  signal_emit('write to file', "$title\n$genre\n$plot\n") if ($chan =~ /sysarmy|moob/);
  return;
}

sub sayit {
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}
signal_add("search imdb","do_imdb");

