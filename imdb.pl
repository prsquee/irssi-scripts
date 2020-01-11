#omdb api http://omdbapi.com/
use Irssi qw(signal_add print signal_emit settings_get_str settings_add_str);
use strict;
use LWP::UserAgent;
use URI::Escape qw( uri_escape );
use Data::Dumper;
use JSON;

signal_add("search imdb", "do_imdb");
settings_add_str('omdb', 'omdb_apikey', '');


my $json = JSON->new();
my $ua   = LWP::UserAgent->new(timeout => '10');

sub do_imdb {
  my ($server, $chan, $text) = @_;
  my $apikey = 'apikey=' . settings_get_str('omdb_apikey');
  my $param = 't';
  my $query = undef;
  my $year  = undef;

  if ($text =~ /^tt\d+/) {
    $param = 'i';
    $query = $text;
  }
  elsif (($query) = $text =~ /^!imdb\s+(.*)$/) {
    ($year) = $query =~ /(\d{4})$/;
    $query =~ s/\d{4}$// if $year;
    $query = uri_escape($query);
  }
  unless ($query) {
    sayit($server, $chan, 'I need a movie title');
    return;
  }

  my $url = 'http://www.omdbapi.com/?' . ${apikey} . '&' . ${param} . '=' . ${query};
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
  my $link = ($text =~ /^!imdb/) ? 'https://www.imdb.com/title/' . $imdb->{imdbID} 
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

