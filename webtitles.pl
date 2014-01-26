#webfetchtitle 
use Irssi qw(signal_emit signal_add print settings_get_str) ;
use LWP::UserAgent;
use strict;
use Data::Dumper;
use Digest::MD5 qw(md5_hex);

my $ua = LWP::UserAgent->new (
  agent             => settings_get_str('myUserAgent'),
  default_headers   =>  HTTP::Headers->new,
  protocols_allowed => ['http', 'https'],
  max_redirect      => 3,
  timeout           => 15
);

our %links = ();

sub go_fetch {
  my ($server,$chan,$url) = @_;
  my $out = '';
  
  if (not exists ($links{md5_hex($url)})) { 
    my $response = $ua->get($url); 
    if ($response->is_success) {
      if ($response->title) {
        my $title = $response->title;
        if ($title) {
          $title =~ s/9gag/9FAG/ig;
          $out = "[link title] $title";
          sayit($server, $chan, $out);
          $links{md5_hex($url)} = $out;
        }
        if ($url =~ /imgur/i) {
          my ($shortRedditLink) = $response->decoded_content =~ m{"http://www\.reddit\.com/\w/\w+/comments/(\w+)/[^"]+"};
          if (defined($shortRedditLink)) {
            my $shortReddit = "[sauce] http://redd.it/${shortRedditLink}";
            sayit($server,$chan,"$shortReddit");
            $links{md5_hex($url)} .= ' :: ' . $shortReddit;
          } # dont have a reddit thread
        } #not imgur 
      } else { print (CRAP "no title."); }
    } else { print (CRAP "no success."); } 
  } else { sayit($server, $chan, $links{md5_hex($url)}); }
  return;
}
sub sayit {
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}
signal_add("check title","go_fetch");
