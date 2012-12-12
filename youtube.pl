#check youtube title and desc
use Irssi qw (signal_add print settings_get_str );
use warnings;
use strict;
use IO::Socket::INET; #TODO this is so ugly, I need to use json asap

sub fetch_tubes {
	my($server,$chan,$vid) = @_;
  my ($title, $desc, $time, $views) = get_title($vid) if ($vid);
  if($title) {
    if ($time < 10) {
      $time = "[0:0${time}]";
    } elsif ($time < 60) {
        $time = "[0:${time}]";
    } elsif ($time >= 60) {
          use integer;
          my $min = $time / 60;
          my $sec = $time % 60;
          $sec = "0" . $sec if ($sec < 10);
          $time = "[${min}:${sec}]";
    }
    my $msg = "[YT]" . $time . " - " . "\x02${title}\x02";
    $msg .= " - $desc" if ($desc); 
    $msg .= " - Views: $views" if ($views);
    sayit($server, $chan, $msg);
  } else { return; }
}

# http://code.google.com/apis/youtube/2.0/developers_guide_protocol.html
sub get_title {
	my $vid = shift;

	my $sock = IO::Socket::INET->new( 
		PeerAddr=>'gdata.youtube.com',
		PeerPort=>'http(80)',
		Proto=>'tcp',
	);
	
	my $req = "GET /feeds/api/videos/$vid HTTP/1.0\r\n";
	$req .= "host: gdata.youtube.com\r\n";
	$req .= "user-agent: UserAgent 1.0\r\n";
	$req .= "\r\n";
	print $sock $req;     #oh the humanity T_T

	my $title; my $desc; my $time; my $views;
	while(<$sock>) {
		($title) = $_ =~ /<media:title type='plain'>(.*?)<\/media:title>/;
		($desc) = $_ =~ /<media:description type='plain'>(.*?)<\/media:description>/;
		($time) = $_ =~ /<yt:duration seconds='(\d+)'/;
		($views) = $_ =~ /viewCount='(\d+)'/;
	}
	close $sock;
	return ($title,$desc,$time,$views);
}
sub sayit {
	my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}
signal_add("check tubes", "fetch_tubes"); 
