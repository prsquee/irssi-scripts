#adminbirras
# this is prolly the worst way to use an api
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
use LWP::UserAgent;
use Data::Dumper;
use JSON;
use Encode qw(encode decode);
use utf8;

settings_add_str('meetup', 'meetup_apikey', '');
signal_add('birras get','say_event');

my $json = JSON->new();
my $ua   = LWP::UserAgent->new( timeout => '15' );

my $this_group = 'sysarmy';
my $birra_meetup_url = 'https://api.meetup.com/2/events?key='
                     .  settings_get_str('meetup_apikey')
                     . '&group_urlname=' . $this_group
                     . '&sign=true'
                     . '&fields=short_link'
                     ;

my $tag_is_set = undef;

sub say_event {
  my ($server, $chan) = @_;
  my @this_event = fetch_event();
  my $event_time = pop @this_event;

  sayit($server, $chan, '🍺 ' . join(' :: ', @this_event));

  # we only need the name, date and the link for the topic
  is_topic_set($chan, join(' :: ', @this_event[0,1,2]));

  check_tag_for($event_time, $chan, @this_event[0,1,2]);
}

#{{{ this is so fetch!
sub fetch_event {
  my $response = $ua->get($birra_meetup_url);
  if ($response->is_success) {
    my $parsed_json = eval { $json->utf8->decode($response->decoded_content) };
    print (CRAP $@) if $@;

    if (scalar @{ $parsed_json->{'results'} } == 0) {
      return '🍺 No event not created at meetup.com.';
      # now this should never be the case.
    }
    else {
      #we just need the 1st result.
      #print strftime '%A, %h %d at %H:%M', localtime 1432936800;
      my $event = shift @{ $parsed_json->{'results'} };
      if ($event->{'status'} eq 'upcoming') {
        my @output;
        push @output, $event->{'name'};
        push @output, get_dates($event->{'time'}/1000);
        push @output, $event->{'venue'}->{'name'}       . ', '
                    . $event->{'venue'}->{'address_1'}  . ' '
                    . $event->{'venue'}->{'address_2'}  . ', '
                    . $event->{'venue'}->{'city'};

        push @output, $event->{'yes_rsvp_count'} . ' going';
        push @output, $event->{'short_link'};
        push @output, $event->{'time'};

        #return join (' :: ', @output);
        return @output;
      }
    }
  }
  else {
    print (CRAP "meetup.com error code: $response->{status_line}");
  }
}
# }}}
# {{{ dating service
sub get_dates {
  my ($event_time) = @_;
  if (strftime('%F', localtime) eq strftime('%F', localtime($event_time))) {
    return 'TONIGHT at ' . strftime('%H:%M', localtime($event_time));
  }
  else {
    return strftime('%A, %h %d at %H:%M', localtime($event_time));
  }
}
# }}}
#{{{ no need to calculate this manually anymore 
#sub next_birra {
#  my $today = strftime('%u', localtime);
#
#  # odd_week = yes birra ; even_week = no birra
#  # is this week a birra week? (swap 1 and 0 to toggle)
#  my $is_birraweek = (strftime('%V', localtime) % 2) ? 0 : 1;
#
#  if ($is_birraweek) {
#    #is it past thusday?
#    return 'today.' if ($today == 4);
#
#    if ($today < 4) {
#      return 'this Thursday.';
#    }
#    else {
#      #past thursday on a birraweek.
#      #jump to next thursday, which will be nonbirraweek, then plus one week.
#      return strftime('%A, %B %d.', localtime(UnixDate('next Thursday', '%s') + 604800));
#    }
#  }
#  else {
#    #this is NOT a birraweek.
#    return UnixDate('next Thursday', '%A, %B %d.') if $today == 4;
#    if ($today < 4) {
#      #we are between Mon and Wed.
#      #jump to next thursday on a non birraweek then + 1 week.
#      return strftime('%A, %B %d.', localtime(UnixDate('next Thursday', '%s') + 604800));
#    }
#    else {
#      return strftime('%A, %B %d.', localtime(UnixDate('next Thursday', '%s')));
#    }
#  }
#}
#}}}
sub check_tag_for {
  my ($event_time, $chan, $new_part) = @_;
  print (CRAP "event time is $event_time");

  #event start time is in miliseconds, diff with now, then +4hs
  unless ($tag_is_set) {
    my $msecs_until_ends = $event_time - time * 1000 + 14400000 + 10;
    $tag_is_set = timeout_add_once($msecs_until_ends, 'refresh_topic', $chan);

    print (CRAP "refresh topic after $msecs_until_ends :: internal tag: $tag_is_set");
  }
  else {
    print (CRAP "internal tag is already set: $tag_is_set");
  }
}
# TODO make tag a hash and save a tag per channel
sub refresh_topic {
  # this means we need to put the next 'new' event onto the topic
  my $chan = shift;
  my @events = fetch_event();
  my $new_part = join(' :: ', @events[0,1,2]);

  # print (CRAP "$chan will have $new_part");
  is_topic_set($chan, $new_part);
}

sub is_topic_set {
  my ($chan, $new_part) = @_;

  # check current topic, if birra part is equal do nothing
  my $current_topic
    = decode('utf8', Irssi::Server->channel_find($chan)->{'topic'});

  if ($current_topic =~ /^#(?:adminbirras)|(?:meetarmy)/i) {
    my @current_topic = split(/ \|\| /, $current_topic);
    my $old_part = shift @current_topic;
    if ($old_part ne $new_part) {
      unshift @current_topic, $new_part;
      set_topic ($chan, encode('utf8', join(' || ', @current_topic)));
    }
    else {
      print (CRAP 'topic is already set for this event.');
    }
  }
  else {
    set_topic ($chan, encode('utf8', $new_part . ' || ' . $current_topic));
  }
}
sub set_topic {
  Irssi::server_find_tag('fnode')->send_message("chanserv", "topic @_", 1);
}
sub sayit { my $s = shift; $s->command("MSG @_"); }
