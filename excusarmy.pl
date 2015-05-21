use Irssi qw (print settings_get_str);
use warnings;
use strict;
use Data::Dumper;
use LWP::UserAgent;
use JSON;

#init 
Irssi::settings_add_str('excusarmy', 'excusarmy_appid', '');
Irssi::settings_add_str('excusarmy', 'excusarmy_restkey','');


my $api_url    = 'https://api.parse.com/1/classes/bohf_regrets';
my $appid      = settings_get_str('excusarmy_appid');
my $rest_key   = settings_get_str('excusarmy_restkey');
my $last_fetch = 0;
my $cached_for = 172800; #2 days

my $json   = JSON->new();
my $ua     = LWP::UserAgent->new( timeout => '30' );
my $preped = HTTP::Request->new( 'GET' => $api_url );

$preped->header('X-Parse-Application-Id' => $appid);
$preped->header('X-Parse-REST-API-Key'   => $rest_key);
$preped->header('content-type' => 'application/json');

#here be regrets
my @regrets = ();

sub fetch_and_cache {
  my $response = $ua->request($preped);
  if ($response->is_success) {
    $last_fetch = time();

    my $parsed_json = eval { $json->utf8->decode($response->decoded_content) };
    #print (CRAP Dumper($parsed_json));
    foreach my $result (@{ $parsed_json->{results} }) {
      #$regrets{ $result->{'objectId'} } = $result->{'regret'} if $result->{'active'};
      push @regrets, $result->{'regret'} if $result->{'active'};
    }
    print (CRAP 'excusarmy updated with ' . scalar(@regrets) . ' excuses.');
  }
  else {
    print (CRAP "excusarmy error code: $preped->code - $preped->message");
  }
}

sub get_regret {
  return $regrets[rand scalar @regrets];
}

#initial fetch
fetch_and_cache;
