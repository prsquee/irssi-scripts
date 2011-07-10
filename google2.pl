#!/usr/bin/perl
# fnode 

use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use strict;
use REST::Google::Search; 
use REST::Google::Search::Images; 

sub msg_pub {
	my($server, $text, $nick, $mask,$chan) = @_;
	do_google($text, $chan, $server) if ($server->{tag} =~ /3dg|fnode|lia|gsg/ and $text =~ /^!(?:g(?:oogle|ugl)?)|(?:pic) /);
	
}

sub do_google {
	my ($text, $chan, $server) = @_;
	my ($gcmd, $query) = $text =~ /^!(\w+) (.*)$/;
	my $res;

	if (!$query) {
		#$server->command("MSG $chan gimme somethin to feed the beast");
		return;
	} 
	if ($query =~ /techmez/i) {
		$server->command("MSG $chan No lo vi primero en techmez!");
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
		}
		#return if ( !$& );
	}
			
#	my $res = REST::Google::Search->new( 
#		q => $query,
#		hl => 'en',
#		rsz => 'small'
#	);
	eval { $res->responseStatus };
	return if ( $@ );
	return if ( $res->responseStatus != 200);  
	my $content = $res->responseData;
	my @results = $content->results;
	#my $links = "[gugl] ";
	my @links; 
	for my $r (0..3) {
		eval { $results[$r]->url }; next if ( $@ );	#testear si encontro algo o no, otherwise accediendo url method will crash
		$links[$r] = $results[$r]->url;
		$@ == 0; 
	}
	if ( ! @links ) {
	       $server->command("MSG $chan no encontre nada en gugl :|");
       } else { 
	       for my $i (0..3) {
		       return if ( ! $links[$i]);
		       $server->command("MSG $chan [gugl] $links[$i]"); 
	       }
       }
}
sub print_msg { active_win()->print("@_"); }
signal_add("message public","msg_pub");

