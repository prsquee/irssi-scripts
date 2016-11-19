#adminbirras
use Irssi qw (
  signal_add
  print
  settings_get_str
  settings_add_str
  timeout_add_once
  server_find_tag
);

use strict;
use warnings;
use POSIX qw(strftime);
use Date::Manip;
use LWP::UserAgent;
use Data::Dumper;
use JSON;
use Encode qw(encode decode);
use utf8;

settings_add_str('meetup', 'meetup_apikey', '');
signal_add('birras get','get_event');

my $json = JSON->new();
my $ua   = LWP::UserAgent->new( timeout => '15' );

my $this_group = 'sysarmy';
my $url  = 'https://api.meetup.com/2/events?key='
         .  settings_get_str('meetup_apikey')
         . '&group_urlname=' . $this_group
         . '&sign=true'
         . '&fields=short_link'
         ;

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
        my $output = $event->{'name'} . ' :: '
                   . get_dates($event->{'time'}/1000)
                   . ' :: '
                   . $event->{'venue'}->{'name'}      . ', '
                   . $event->{'venue'}->{'address_1'} . ', '
                   . $event->{'venue'}->{'city'}
                   . ' :: '
                   . $event->{'yes_rsvp_count'} . ' going'
                   . ' :: '
                   . $event->{'short_link'}
                   ;

        sayit($server, $chan, '🍺 ' . $output);

        # we only need the name, date and the link for the topic
        my @split_event = split(' :: ', $output);
        my $add_this_to_topic = join (' :: ', @split_event[0,2,5]);

        check_topic_for($server, $chan, $add_this_to_topic, $event->{'time'});
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

sub check_topic_for {
  my ($server, $chan, $add_this, $event_time) = @_;

  # check current topic, if set do nothing
  my $current_topic = decode('utf8', $server->channel_find($chan)->{'topic'});

  unless ($current_topic =~ /^adminbirra/i ) {
    # topic not set with this event.
    set_topic($chan, encode('utf8', $add_this . ' || ' . $current_topic));

    # event start time is in miliseconds, diff with now, then +4hs
    my $event_ends_at = $event_time - time * 1000 + 14400000;
    timeout_add_once($event_ends_at, 'restore_topic', $chan);
    print (CRAP "topic set for $chan and will be removed in $event_ends_at msecs.");
  }
  # else topic is already set.
}

sub restore_topic {
  my $chan = shift;
  my $birra_topic = Irssi::Server->channel_find($chan)->{'topic'};
  my @birra_topic = split(/ \|\| /, $birra_topic);
  shift @birra_topic;
  my $old_topic = join(' || ', @birra_topic);
  set_topic($chan, $old_topic);
}

sub set_topic { Irssi::server_find_tag('fnode')->send_message("chanserv", "topic @_", 1); }
sub sayit { my $s = shift; $s->command("MSG @_"); }
