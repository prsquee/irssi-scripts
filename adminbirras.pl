#adminbirras

use Irssi qw ( signal_add print settings_get_str settings_add_str timeout_add_once server_find_tag get_irssi_dir);
use strict;
use warnings;
use POSIX qw(strftime);
use Data::Dumper;
use Date::Manip::Date;
use Encode qw(encode decode);
use utf8;

signal_add('birras get','say_event');

my @months_names = qw(January February March April May June July August September October November December);
my $birradate = new Date::Manip::Date;
my $tag_is_set = undef;
my $birra_venue = ' :: Location: Genk Beer House, Honduras 5254 :: Map: https://g.page/GenkBeerHouse :: Event: https://sysar.my/meetup';

sub say_event {
  my ($server, $chan) = @_;
  my ($sec,$min,$hour,$today,$this_month,$year,$wday,$yday,$isdst) = localtime(time);

  $birradate->parse('First Thursday in ' . $months_names[$this_month]);

  if ($today > $birradate->printf('%e')) {
    $birradate->parse('First Thursday in ' . $months_names[++$this_month]);
    sayit($server, $chan, 'Next 🍻 on ' . $birradate->printf('%B %d') . ' at 8pm.' . $birra_venue);
  }
  elsif ($today == $birradate->printf('%e')) {
    sayit($server, $chan, '🍺 + 🍺 = 🍻 IS TONIGHT at 8pm!! 🍺🥳' . $birra_venue);
    return;
  }
  else {
    sayit($server, $chan, 'Next 🍻 on ' . $birradate->printf('%B %d') . ' at 8pm' . $birra_venue);
  }
  is_topic_set($chan, '#AdminBirras :: ' . $birradate->printf('%B %d') . ' :: Genk Beer House - Honduras 5254 - CABA :: https://sysar.my/meetup');
  return;
}

sub is_topic_set {
  my ($chan, $new_part) = @_;
  print (CRAP "new: $new_part");

  my $current_topic = decode('utf8', Irssi::Server->channel_find($chan)->{'topic'});
  $current_topic =~ s/\x{a0}/ /g; 
  print (CRAP "current: Dumper($current_topic)");

  if ($current_topic =~ /^#AdminBirras/) {
    my @current_topic = split / \|\| /, $current_topic;
    print (CRAP Dumper(@current_topic));
    my $old_part = shift @current_topic;
    print (CRAP "old: $old_part");
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
