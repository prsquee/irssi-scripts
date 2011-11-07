# google search
# http://search.cpan.org/~manwar/WWW-Google-CustomSearch-0.04/lib/WWW/Google/CustomSearch.pm
#
use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use URI::Escape qw( uri_unescape uri_escape );
#use Data::Dumper;
use WWW::Google::CustomSearch;
           

sub msg_pub {
	my($server, $text, $nick, $mask,$chan) = @_;
	do_google($text, $chan, $server) if ($server->{tag} =~ /3dg|fnode|lia|gsg/ and $text =~ /^!(?:(g(oogle)?))/);
	
}

sub do_google {
	my ($text, $chan, $server) = @_;
	my ($query) = $text =~ /^!g(?:oogle)? (.*)$/;

	if (!$query) {
		sayit($server,$chan,"gimme somethin to feed the beast");
		return;
	} 
	if ($query =~ /techmez/i) {
		sayit($server, $chan,"No lo vi primero en techmez!");
		return;
	}
	my $query8 = uri_escape($query);
	my $engine  = WWW::Google::CustomSearch->new(
		api_key => Irssi::settings_get_str('search_apikey'),
		alt => json,
	       	cx => Irssi::settings_get_str('engine_id'),
		num => 4
	);
	my $res = $engine->search($query8);
	#el obj 'queries' contiene 2 arrays, 'nextPage' y 'request'.
	#cada uno es un array de un solo value.
	#easy value contiene varios objects mas.
	#so, we have:
	#${$res->{queries}->{request}}[0]{totalResults}");
	#i dont wanna do this anymore :(
	#this looks better tho:
	if ($res->{queries}->{request}->[0]{totalResults} > 0) {
		foreach my $items (@{$res->{items}}) {
			my $title = ($items->{title});
			my $link  = ($items->{link});
			sayit($server,$chan,"[gugl] $link - \x20$title\x20");
		}
	} else {
		sayit($server,$chan,"found nothin'");
		return;
	}
}
sub sayit { 
        my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}                                         
sub print_msg { active_win()->print("@_"); }
signal_add("message public","msg_pub");
Irssi::settings_add_str('gsearch', 'search_apikey', '');
Irssi::settings_add_str('gsearch', 'engine_id', '');
