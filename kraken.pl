# kraken public api
use Irssi qw(signal_add print settings_get_str settings_add_str) ;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Data::Dumper;
 
signal_add('kraken released', 'toss_coins');

my $json = JSON->new();
my $ua  = LWP::UserAgent->new( timeout => 15 );

my $buffered_for = 1800;

my %coins = (
  'btc' => {
    'price'      => 0,
    'last_fetch' => 0,
    'decimals'   => 2,
    'asset_name' => 'XXBT'
  },
  'xlm' => {
    'price'      => 0,
    'last_fetch' => 0,
    'decimals'   => 5,
    'asset_name' => 'XXLM'
  },
  'eth' => {
    'price'      => 0,
    'last_fetch' => 0,
    'decimals'   => 5,
    'asset_name' => 'XETH'
  },
  'ltc' => {
    'price'      => 0,
    'last_fetch' => 0,
    'decimals'   => 5,
    'asset_name' => 'XLTC'
  },
);

sub toss_coins {
  my ($server, $chan, $this_coin, $this_much) = @_ ;
  if (exists $coins{$this_coin}) {
    fetch_prices_for($this_coin);
    if ($coins{$this_coin}->{'price'}) {
      sayit($server, $chan, '[kraken] $' . sprintf('%.'.$coins{$this_coin}->{'decimals'}.'f', eval($coins{$this_coin}->{'price'} * $this_much)));
    }
    else {
      sayit($server, $chan, "I don't have a price right now.");
    }
  }
}

sub fetch_prices_for {
  my $this_coin = shift;

  return $coins{$this_coin}->{'price'} unless time - $coins{$this_coin}->{'last_fetch'} > $buffered_for;

  my $assetpair = $coins{$this_coin}->{'asset_name'} . 'ZUSD';
  my $kraken = 'https://api.kraken.com/0/public/Ticker?pair=' . $assetpair;

  $ua->agent(settings_get_str('myUserAgent'));

  my $got = $ua->get($kraken);
  unless ($got->is_success) {
    print (CRAP "kraken not released");
    return;
  }

  my $parsed_json = eval { $json->utf8->decode($got->decoded_content) };
  return if $@;
  #print (CRAP Dumper($parsed_json));

  if ( scalar @{$parsed_json->{'error'}} == 0) {
    $coins{$this_coin}->{'last_fetch'} = time;
    $coins{$this_coin}->{'price'} = $parsed_json->{'result'}->{"$assetpair"}->{'p'}[0];
    # p[0] is today's volume weighted average price
    return $coins{$this_coin}->{'price'};
  }
  else {
    print(CRAP Dumper($parsed_json->{'error'}));
    #return undef;
  }
}
sub sayit { my $s = shift; $s->command("MSG @_"); }
