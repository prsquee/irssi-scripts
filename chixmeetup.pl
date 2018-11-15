#chix meetup
use Irssi qw (signal_add print settings_get_str settings_add_str);
use strict;
use warnings;
use POSIX qw(strftime);
use LWP::UserAgent;
use Data::Dumper;
use JSON;

settings_add_str('meetup', 'meetup_apikey', '');
settings_add_str('bot config', 'halp_linuxchix', '!meetup');
signal_add('chix meetup','get_event');

my $json = JSON->new();
my $ua   = LWP::UserAgent->new( timeout => '15' );

my $group = 'LinuxChix-Argentina-sede-CABA';
my $url  = 'https://api.meetup.com/2/events?key='
         . settings_get_str('meetup_apikey')
         . '&group_urlname=' . $group . '&sign=true';

sub get_event {
  my ($server, $chan) = @_;
  my $response = $ua->get($url);
  if ($response->is_success) {
    my $parsed_json = eval { $json->utf8->decode($response->decoded_content) };

    if (scalar @{ $parsed_json->{'results'} } == 0) {
      my $nope = 'Event not created at meetup.com yet.';
      sayit($server, $chan, $nope);
      return;
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
        sayit($server, $chan, $output);
      }
    }
  }
  else {
    print (CRAP "meetup.com error code: $response->code - $response->message");
  }
}

sub sayit { my $s = shift; $s->command("MSG @_"); }
