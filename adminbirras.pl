#adminbirras
#'buying_mode' => 'buy_it_now' || acution
use Irssi qw (signal_add print settings_get_str signal_emit);
use strict;
use warnings;
use POSIX qw(strftime);
use LWP::UserAgent;
use Data::Dumper;
use JSON;

Irssi::settings_add_str('meetup', 'meetup_apikey', '');

my $json = JSON->new();
my $ua   = LWP::UserAgent->new( timeout => '15' );

my $group = 'sysarmy';
my $url  = 'https://api.meetup.com/2/events?key='
         . settings_get_str('meetup_apikey')
         . '&group_urlname=' . $group . '&sign=true';

sub get_event {
  my $response = $ua->get($url);
  if ($response->is_success) {
    my $parsed_json = eval { $json->utf8->decode($response->decoded_content) };
    
    if (scalar @{ $parsed_json->{'results'} } == 0) {
      return 'No confirmed dates for upcoming adminbirras.';
      #add a prolly next thursday based on week number.
    }
    else {
      #we just need the 1st result.
      #print strftime '%A, %h %d at %H:%M', localtime 1432936800;
      my $event = shift @{ $parsed_json->{'results'}};
      if ($event->{'status'} eq 'upcoming') {
        my $output = $event->{'name'} . ' :: '
                   . strftime('%A, %h %d at %H:%M', localtime ($event->{'time'}/1000))
                   . ' :: '
                   . $event->{'venue'}->{'name'}      . ', '
                   . $event->{'venue'}->{'address_1'} . ', '
                   . $event->{'venue'}->{'city'}
                   . ' :: '
                   . $event->{'yes_rsvp_count'} . ' going'
                   . ' :: '
                   . scalar('Irssi::Script::ggl')->can('do_shortme')->($event->{'event_url'})
                   ;
        return $output;
      }
    }
  }
  else {
    print (CRAP "meetup.com error code: $response->code - $response->message");
  }
}
