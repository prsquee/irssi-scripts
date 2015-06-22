#omdb api http://omdbapi.com/
use Irssi qw(signal_add print signal_emit) ;
use strict;
use LWP::UserAgent;
use URI::Escape qw( uri_escape );
use Data::Dumper;
use JSON;

signal_add("search imdb", "do_imdb");

my $json = JSON->new();
my $ua   = LWP::UserAgent->new(timeout => '15');

sub do_imdb {
  my ($server, $chan, $text) = @_;
  my $param = undef;
  my $query = undef;
  my $year  = undef;

  if ($text =~ /^tt\d+/) {
    $param = 'i';
    $query = $text;
  } 
  elsif ($text =~ /^!imdb\s+(.*)$/) { 
    $query = $1;
    if ($query =~ /(19|20\d{2})$/) {
      $year = $1;
      $query =~ s/ \d{4}$//;
    }
    $query = uri_escape($query);
    $param = 't';
  }
  unless ($query) {
    sayit($server, $chan, 'I need a movie title');
    return;
  }
  my $url = "http://www.omdbapi.com/?${param}=${query}" if $param and $query;
  $url .= "&y=${year}" if $year;

  my $got = $ua->get($url);
  unless ($got->is_success) {
    print (CRAP 'imdb error code: ' . $got->code . ' - ' . $got->message);
    return;
  }

  my $imdb = eval { $json->utf8->decode($got->decoded_content) };
  return if $@;
  
  if ($imdb->{Response} !~ /True/ ) {
    sayit($server, $chan, 'not found, try with the full name.');
    return;
  }
  my $link = ($text =~ /^!imdb/) ? 'http://www.imdb.com/title/' . $imdb->{imdbID} 
                                 : undef;
  my $title = "$imdb->{Title} [$imdb->{Year}] - $imdb->{Genre} - " 
            . "Directed by $imdb->{Director}";

  my $actor = "Actors: $imdb->{Actors}";
  my $plot  = "Plot: $imdb->{Plot}";
  $plot .= ($link) ? " - [${link}]" : '';

  sayit($server, $chan, $title);
  sayit($server, $chan, $actor);
  sayit($server, $chan, $plot);
  return;
}
sub sayit { my $s = shift; $s->command("MSG @_"); }

