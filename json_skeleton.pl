# put a link to api doc
#
use Irssi qw(signal_add print settings_add_str settings_get_str);
use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Data::Dumper;
use utf8;

#init
signal_add("signal name", "call_this_func");
settings_add_str('apikey', 'service_name', '');

my $api_url = 'https://apiuurl.com';
my $api_key = settings_get_str('service_name');

sub call_this_func {
  ...
}
sub sayit { my $s = shift; $s->command("MSG @_");  }
