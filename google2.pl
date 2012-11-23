#OLD OLD OLD OLD 
# google search
# DEPRECATED
# DEPRECATED
# DEPRECATED
# DEPRECATED
# DEPRECATED
# DEPRECATED
# DEPRECATED
# DEPRECATED
# DEPRECATED
# DEPRECATED
# DEPRECATED
# DEPRECATED

use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use strict;
use REST::Google::Search; 
use REST::Google::Search::Images; 
use REST::Google::Search::News;
use URI::Escape qw( uri_unescape);

sub msg_pub {
	my($server, $text, $nick, $mask,$chan) = @_;
	do_google($text, $chan, $server) if ($server->{tag} =~ /3dg|fnode|lia|gsg/ and $text =~ /^!(?:(g(oogle)?)|(pic)|(news)|(noticias))/);
	
}

sub do_google {
	my ($text, $chan, $server) = @_;
	my ($gcmd, $query) = $text =~ /^!(\w+) (.*)$/;
	my $res;

	if (!$query) {
		sayit($server,$chan,"gimme somethin to feed the beast");
		return;
	} 
	if ($query =~ /techmez/i) {
		sayit($server, $chan,"No lo vi primero en techmez!");
		return;
	}

	$query =~ s/fail/tech/i if ($query =~ /failmez/i); 
	$query = "'".$query."'";
        REST::Google->http_referer('http://www.google.com');
	if ($gcmd) {
		$_ = $gcmd;
		{
			/^(?:g(?:oogle|ugl)?)$/	and do { $res = REST::Google::Search->new( q => $query, service => 'web', hl => 'en', rsz => 'small' ); };
			/^pic$/			and do { $res = REST::Google::Search::Images->new( q => $query, rsz => 'small' ); };
			/^news$/		and do { $res = REST::Google::Search::News->new( q => $query, hl => 'en' ); };
			/^noticias$/		and do { $res = REST::Google::Search::News->new( q => $query, hl => 'es' ); };
		}
		#return if ( !$& );
	}
			
	eval { $res->responseStatus };
	return if ( $@ );
	return if ( $res->responseStatus != 200);  
	my $content = $res->responseData;
	my @results = $content->results;
	my @links; 
	for my $r (0..3) {
		eval { $results[$r]->url }; next if ( $@ );	#testear si encontro algo o no, otherwise accediendo url method will crash
		$links[$r] = $results[$r]->url;
		$@ == 0; 
	}
	if ( ! @links ) {
	       sayit($server,$chan, "no encontre nada en gugl :|");
       } else { 
	       for my $i (0..3) {
		       return if ( ! $links[$i]);
		       my $link = uri_unescape($links[$i]);
		       sayit($server,$chan,"[gugl] $link"); 
	       }
       }
}
sub sayit { 
        my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}                                         
sub print_msg { active_win()->print("@_"); }
signal_add("message public","msg_pub");
