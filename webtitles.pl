#webfetchtitle 
use Irssi qw(signal_emit signal_add print settings_get_str) ;
use LWP::UserAgent;
use strict;
use Data::Dumper;
use Encode qw(encode decode is_utf8);
use Encode::Detect::Detector qw(detect);

my $ua = new LWP::UserAgent;
$ua->agent(settings_get_str('myUserAgent'));
$ua->protocols_allowed( [ 'http', 'https'] );
$ua->max_redirect( 3 );
$ua->timeout( 15 );

sub go_fetch {
  my ($server,$chan,$url) = @_;
  my $out = "\n";
  my $response = $ua->head( $url ); #para ver q es 
  if ($response->is_success) {
    if ($response->content_is_html) {
      #print (CRAP Dumper($response));
      my $got = $ua->get( $url );
      #print (CRAP Dumper($got->decoded_content));
      my $t = $got->title if ($got->title);
      #print (CRAP Dumper($got->content_type));
      #my ($type,$charset) = $got->content_type;
      #print (CRAP $charset);
      #my $enc = undef;
      my $title = $t;
      #print (CRAP "$url || $title");
      #if ($type =~ /text/ and defined($charset) and $charset !~ /utf-?8/i) {
      #  $enc = detect($t);
      #  eval { $title = decode($enc,$t) if (defined($enc)) };
      #  $title = $t if ($@ or not defined($enc));
      #} else {
      #  $title = $t;
      #}
      #return if ($title =~ /the simple image sharer/i);       #we all know this already
      if ($title) {
        $title =~ s/9gag/9FAG/ig;
        $out = "[link title] $title";
        sayit($server, $chan, $out);
        $out = $out . "\n";
      }
      if ($url =~ /imgur/) {
        #check si hay un link a reddit and make a short link, fuck API
        my ($shortRedditLink) = $got->decoded_content =~ m{"http://www\.reddit\.com/\w/\w+/comments/(\w+)/[^"]+"};
        $shortRedditLink = "http://redd.it/$shortRedditLink" if ($shortRedditLink);
        sayit($server,$chan,"[sauce] $shortRedditLink") if ($shortRedditLink);
        $out .= "[sauce] $shortRedditLink\n" if ($shortRedditLink);
      } 
    } #else { print (CRAP "not html"); }
  } #else { print (CRAP $response->statusline); }
  
  signal_emit('write to file',"$out") if ($chan =~ /sysarmy|moob/);
  return;
}
sub sayit {
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}
signal_add("check title","go_fetch");
