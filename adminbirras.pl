#adminbirras
use Irssi qw (signal_add print settings_get_str settings_add_str);
use strict;
use warnings;
use POSIX qw(strftime);
use Date::Manip;
use LWP::UserAgent;
use Data::Dumper;
use JSON;
use utf8;

settings_add_str('meetup', 'meetup_apikey', '');
signal_add('birras get','get_event');

my $json = JSON->new();
my $ua   = LWP::UserAgent->new( timeout => '15' );

my $group = 'sysarmy';
my $url  = 'https://api.meetup.com/2/events?key='
         . settings_get_str('meetup_apikey')
         . '&group_urlname=' . $group . '&sign=true';

sub get_event {
  my ($server, $chan) = @_;
  my $response = $ua->get($url);
  if ($response->is_success) {
    my $parsed_json = eval { $json->utf8->decode($response->decoded_content) };

    if (scalar @{ $parsed_json->{'results'} } == 0) {
      my $nope = '🍺 Event not created at meetup.com yet, but the next one should be ';
      my $next_date = next_birra();

      sayit($server, $chan, $nope . $next_date);
    }
    else {
      #we just need the 1st result.
      #print strftime '%A, %h %d at %H:%M', localtime 1432936800;
      my $event = shift @{ $parsed_json->{'results'}};
      if ($event->{'status'} eq 'upcoming') {
        my $output = '🍺 '. $event->{'name'} . ' :: '
                   . get_dates($event->{'time'}/1000)
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
sub get_dates {
  my ($event_time) = @_;
  if (strftime('%F', localtime) eq strftime('%F', localtime($event_time))) {
    return 'TONIGHT at ' . strftime('%H:%M', localtime($event_time));
  }
  else {
    return strftime('%A, %h %d at %H:%M', localtime($event_time));
  }
}
sub next_birra {
  my $today = strftime('%u', localtime);

  # odd_week = yes birra ; even_week = no birra
  # is this week a birra week? (swap 1 and 0 to toggle)
  my $is_birraweek = (strftime('%V', localtime) % 2) ? 0 : 1;

  if ($is_birraweek) {
    #is it past thusday?
    return 'today.' if ($today == 4);

    if ($today < 4) {
      return 'this Thursday.';
    }
    else {
      #past thursday on a birraweek.
      #jump to next thursday, which will be nonbirraweek, then plus one week.
      return strftime('%A, %B %d.', localtime(UnixDate('next Thursday', '%s') + 604800));
    }
  }
  else {
    #this is NOT a birraweek.
    return UnixDate('next Thursday', '%A, %B %d.') if $today == 4;
    if ($today < 4) {
      #we are between Mon and Wed.
      #jump to next thursday on a non birraweek then + 1 week.
      return strftime('%A, %B %d.', localtime(UnixDate('next Thursday', '%s') + 604800));
    }
    else {
      return strftime('%A, %B %d.', localtime(UnixDate('next Thursday', '%s')));
    }
  }
}

sub sayit { my $s = shift; $s->command("MSG @_"); }
