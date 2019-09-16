#adminbirras
# this is prolly the worst way to use an api
use Irssi qw (
  signal_add
  print
  settings_get_str
  settings_add_str
  timeout_add_once
  server_find_tag
  get_irssi_dir
);

use strict;
use warnings;
use POSIX qw(strftime);
use Data::Dumper;
use JSON;
use Encode qw(encode decode);
use Net::OAuth2::Client;
use Storable qw (store retrieve);
use utf8;

settings_add_str('meetup', 'meetup_client_id', '');
settings_add_str('meetup', 'meetup_client_secret', '');
signal_add('birras get','say_event');

my $json = JSON->new();
my $client_id = settings_get_str('meetup_client_id');
my $client_secret = settings_get_str('meetup_client_secret');
my $redirect_uri = 'https://fnord.com.ar';
my $birra_meetup_url = 'https://api.meetup.com/sysarmy/events?&sign=true&photo-host=public&page=1&fields=short_link&status=upcoming';

my $site = 'https://api.meetup.com';
my $auth_url = 'https://secure.meetup.com/oauth2/authorize';
my $access_token_url  = 'https://secure.meetup.com/oauth2/access';
my $token_file = get_irssi_dir() . '/scripts/datafiles//meetup_token.storable';
my $access_token = undef;

my $meetup = Net::OAuth2::Profile::WebServer->new(
        name          => 'meetup.com',
        client_id     => $client_id,
        client_secret => $client_secret,
        grant_type    => 'authorization_code',
        site          => $site,
        redirect_uri  => $redirect_uri,
        authorize_url => $auth_url,
        access_token_url  => $access_token_url,
        refresh_token_url => $access_token_url,
);

if (-r $token_file) {
  my $session = retrieve($token_file);
  $access_token = Net::OAuth2::AccessToken->session_thaw($session, profile => $meetup);
}
else {
  print (CRAP 'no token found. use gettokens.pl');
  return;
  # say($meetup->authorize_response->as_string);
  # my $code = <STDIN>;
  # chop($code);
  # say("code is $code");
  # $access_token = $meetup->get_access_token( $code, resource => $client_id );
}

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
  my $response = $access_token->get($birra_meetup_url);
  if ($response->is_success) {
    my $parsed_json = eval { $json->utf8->decode($response->decoded_content) };
    print (CRAP $@) if $@;

    if (scalar @{$parsed_json} == 0) {
      return '🍺 No events created at meetup.com.';
      # now this should never be the case.
    }
    else {
      #print strftime '%A, %h %d at %H:%M', localtime 1432936800;
      my $event = shift @{$parsed_json};
      if ($event->{'status'} eq 'upcoming') {
        my @output;
        push @output, $event->{'name'};
        push @output, get_dates($event->{'time'}/1000);
        push @output, $event->{'venue'}->{'name'} . ', ' . $event->{'venue'}->{'address_1'};
        push @output, $event->{'yes_rsvp_count'} . ' going';
        push @output, $event->{'short_link'};
        push @output, $event->{'time'};
        return @output;
      }
    }
    # save the refreshed token, just in case. Not really needed.
    my $newtoken = $access_token->session_freeze;
    store $newtoken, $token_file;
  }
  else {
    print (CRAP 'meetup.com error code: ' . $response->status_line());
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

sub check_tag_for {
  my ($event_time, $chan, $new_part) = @_;
  print (CRAP "event time is $event_time");

  #event start time is in miliseconds, diff with now, then +4hs
  unless ($tag_is_set) {
    my $msecs_until_ends = $event_time - time * 1000 + 14400000 + 10;
    $tag_is_set = timeout_add_once($msecs_until_ends, 'refresh_topic', $chan);

    print (CRAP "$chan: refresh topic after $msecs_until_ends msecs :: internal tag: $tag_is_set");
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
