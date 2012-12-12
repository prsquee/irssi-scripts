#webfetchtitle 
use Irssi qw(signal_add print settings_get_str) ;
use LWP::UserAgent;
use strict;
#use HTML::Entities;
use Data::Dumper;

my $ua = new LWP::UserAgent;
$ua->agent(settings_get_str('myUserAgent'));
$ua->protocols_allowed( [ 'http', 'https'] );
$ua->max_redirect( 4 );
$ua->timeout( 15 );

sub do_fetch {
	my ($server,$chan,$url) = @_;

	my $response = $ua->head( $url ); #para ver q es 
	if ($response->is_success) {
		if ($response->content_is_html) {
			my $got = $ua->get( $url );
			#return if no desc available
			my $title = $got->title if ($got->title);
			return if ($title =~ /the simple image sharer/i); #we all know this already
			#$title = HTML::Entities::decode($title) if ($title);
			sayit($server, $chan, "[link title] \x02${title}\x20") if ($title);
			if ($url =~ /imgur/) {
				#check si hay un link a reddit and make a short link, fuck API
				my ($shortRedditLink) = $got->decoded_content =~ m{"http://www\.reddit\.com/\w/\w+/comments/(\w+)/[^"]+"};
        $shortRedditLink = "http://redd.it/$shortRedditLink" if ($shortRedditLink);
				sayit($server,$chan,"[sauce] $shortRedditLink") if ($shortRedditLink);
			}
			return;
		}
	}
}
sub sayit {
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}
signal_add("check title","do_fetch");
