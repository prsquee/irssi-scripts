#the pirate bay search
# http://mgnet.me/api.html

use Irssi qw (signal_add print settings_get_str signal_emit);
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Data::Dumper;

signal_add('arrr','pirate_search');

my $mgnetme = 'http://mgnet.me/api/create?format=json&m=';
my $url   = 'http://thorrents.com/search/';

my $json  = new JSON;
my $ua    = LWP::UserAgent->new(timeout => 10);

$ua->agent(settings_get_str('myUserAgent'));
$ua->timeout(10);

sub pirate_search {
  my ($server, $chan, $booty) = @_;
  my $raw_content = $ua->get($url . $booty . '.json')->content;
  my $decoded_json = $json->utf8->decode($raw_content);

  my $needed = 5;
  my $count  = 0;
  
  # print (CRAP Dumper($decoded_json));
  if (scalar @{$decoded_json->{results}} > 0) {
    foreach my $found ( reverse sort { $a->{seeds} <=> $b->{seeds} } 
                                    @{$decoded_json->{results}}
                      ) {
      last if ($count == $needed);

      chomp($found->{name});
      $found->{name} =~ s/^\s+//; 

      sayit($server, $chan, "$found->{name} - "
                            . "seeds: $found->{seeds} - "
                            . "magnet: " . magfy($found->{magnet})
           );
      $count++;
    }
  }
  else {
    sayit($server, $chan, qq(I got nothin'));
  }
  return;
}
sub magfy {
  my $magnet_url = shift;
  my $parsed_json = $json->decode($ua->get($mgnetme . $magnet_url)->content);
  ($parsed_json->{state} eq 'success') ? return $parsed_json->{shorturl}
                                       : return 'no link';
}

sub sayit { my $s = shift; $s->command("MSG @_"); }
