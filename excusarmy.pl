use Irssi qw (signal_add print settings_get_str settings_add_str);
use warnings;
use strict;
use Data::Dumper;
use LWP::UserAgent;
use JSON;

#init 
settings_add_str('excusarmy', 'excusarmy_appid', '');
settings_add_str('excusarmy', 'excusarmy_restkey','');
signal_add('excusa get','get_regret');
signal_add('excusa add','add_regret');

my $api_url    = 'https://api.parse.com/1/classes/bohf_regrets';
my $appid      = settings_get_str('excusarmy_appid');
my $rest_key   = settings_get_str('excusarmy_restkey');
my $last_fetch = 0;
my $cached_for = 43200; #halfday;

my $json = JSON->new();
my $ua   = LWP::UserAgent->new( timeout => '15' );

my %headers = (
  'X-Parse-Application-Id' => $appid,
  'X-Parse-REST-API-Key'   => $rest_key,
  'content-type'           => 'application/json',
);

my $get = HTTP::Request->new( 
  'GET' => $api_url,
  HTTP::Headers->new(%headers),
);

my $post = HTTP::Request->new( 
  'POST' => $api_url,
  HTTP::Headers->new(%headers),
);

#here be regrets
my @regrets = ();

sub fetch_and_cache {
  my $response = $ua->request($get);
  if ($response->is_success) {
    $last_fetch = time();

    my $parsed_json = eval { $json->utf8->decode($response->decoded_content) };

    @regrets = ();
    foreach my $result (@{ $parsed_json->{results} }) {
      #$regrets{ $result->{'objectId'} } = $result->{'regret'} if $result->{'active'};
      push @regrets, $result->{'regret'} if $result->{'active'};
    }
    print (CRAP 'excusarmy updated with ' . scalar(@regrets) . ' excuses.');
  }
  else {
    print (CRAP "excusarmy error code: $get->code - $get->message");
  }
}

sub get_regret {
  my ($server, $chan) = @_;
  fetch_and_cache if time - $last_fetch > $cached_for;
  #return $regrets[rand scalar @regrets];
  sayit($server, $chan, '[excusarmy] ' . $regrets[int(rand(@regrets))]);
}

sub add_regret {
  my ($server, $chan, $new_regret) = @_;
  my %json_hash = ('active' => JSON::false, 'regret' => $new_regret);
  $post->content(encode_json \%json_hash);
  my $response = $ua->request($post);
  if ($response->code == 201 and $response->message eq 'Created') {
    #my $parsed_json = eval { $json->decode($response->decoded_content) };
    sayit($server, $chan, 'thanks! waiting for approval.');
  }
}

sub sayit { my $s = shift; $s->command("MSG @_"); }
#initial fetch
fetch_and_cache;

