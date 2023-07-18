#youtube stuff
#doc https://developers.google.com/youtube/v3/getting-started

use Irssi qw (signal_add signal_emit print settings_get_str );
use warnings;
use strict;
use Data::Dumper;
use LWP::UserAgent;
use JSON;
use Locale::Country;

#init
signal_add("check tubes", "fetch_tubes");
Irssi::settings_add_str('apikey', 'google_apikey', '');

my %fetched_ids = ();
my $json    = JSON->new();
my $ua      = LWP::UserAgent->new( timeout => '15' );

my $api_url = 'https://www.googleapis.com/youtube/v3/';
#'videos?id=';
my $api_key = '&key=' . settings_get_str('google_apikey');
my $part    = '&part=contentDetails,snippet,statistics';
my $field   = '&fields=items(' . 'contentDetails(duration),' . 'snippet(title),' . 'statistics(viewCount)' . ')';

sub fetch_tubes {
  my($server, $chan, $id) = @_;
  #  print (CRAP length($id));

  if (not exists($fetched_ids{$id})) {
    my $what = ( length($id) == 11 ? 'videos?id=' . $id . $field : 'channels?id=' . $id );
    my $request_url = $api_url . $what . $api_key . $part;
    #print (CRAP $request_url);

    $ua->agent(settings_get_str('myUserAgent'));
    my $got = $ua->get($request_url);
    unless ($got->is_success) {
      print (CRAP "youtube error code: $got->code - $got->message");
      return;
    }

    my $result = eval { $json->utf8->decode($got->decoded_content) };
    return if $@;

    if ($what =~ /^videos/) {
      #items comes as an one element array.
      my $items = shift @{ $result->{'items'} };

      my $title = $items->{'snippet'}->{'title'};
      my $time  = $items->{'contentDetails'}->{'duration'};
      my $views = $items->{'statistics'}->{'viewCount'};

      if ($title) {
        $time = format_time($time);
        my $id_info = "${time} ${title} - [views " . fuzzy_views($views) . "]";
        sayit($server, $chan, $id_info);
        $fetched_ids{$id} = $id_info;
      }
    }
    else {
      my $citems = shift @{ $result->{'items'} };
      my $channel_name = $citems->{'snippet'}->{'title'};
      my $country = code2country($citems->{'snippet'}->{'country'});
      my $subs  = fuzzy_subs($citems->{'statistics'}->{'subscriberCount'});
      sayit ($server, $chan, '[channel] "'. $channel_name . '"' . ' with ' . $subs . ' subscribers.');
    }
  }
  else { sayit ($server, $chan, $fetched_ids{$id}); }
}

sub format_time {
  my $time = shift;
  #time comes in iso 8601 duration format
  #like PT2H11M12S, if the vid is longer than a day: P2DT2H11M12S
  #we match all the integers and start from the last element, seconds.
  my @integers = $time =~ /(\d+)/g;
  $time = join(':', map { sprintf("%02d", $_) } @integers);

  return ($time eq '00') ? '[LIVE]'
        :($time !~ /:/) ? '[00:' . $time . ']'
        : '[' . $time . ']'
        ;
}
sub fuzzy_views {
  my $n = scalar reverse shift;
  $n =~ s/^\d{3}/K/ if $n =~ /^\d{4,6}$/;
  $n =~ s/(\d{3})(?=\d)/$1./g if $n =~ /^\d{7,}$/;
  $n =~ s/^\d{3}\.\d{2}/M/ if $n =~ /[^01]\.\d$/;
  $n =~ s/^\d{3}\.\d{3}\./M/;
  $n =~ s/^M\d{3}\./B/;

  return reverse $n;

}
sub fuzzy_subs {
  my $n = shift;
  print (CRAP "subs: $n");
  $n =~ s/000/K/g;
  $n =~ s/KK$/M/;
  $n =~ s/(\d)M$/.$1M/   if $n =~ s/K00/M/;
  $n =~ s/(\d\d)M$/.$1M/ if $n =~ s/K0/M/;
  return $n;
}
sub sayit { my $s = shift; $s->command("MSG @_"); }
