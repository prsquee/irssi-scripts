#twitter
#http://search.cpan.org/~mmims/Net-Twitter-Lite-0.10004/lib/Net/Twitter/Lite.pm

use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use strict;
use Net::Twitter::Lite; 
use HTML::Entities;
use Data::Dumper;
use WWW::Shorten::Googl;


sub msg_pub {
	my($server, $text, $nick, $mask,$chan) = @_;
	if ($server->{tag} =~ /3dg|fnode|gsg/) {
		do_twittr($text, $chan, $server) 	if ($text =~ m{twitter\.com(/#!)?/[^/]+/status(?:es)?/\d+}i ); 
		do_search($text, $chan, $server) 	if ($text =~ /^!searchtwt/ );
		do_showuser($text, $chan, $server) 	if ($text =~ /^\@user/ );
		do_last($text, $chan, $server) 		if ($text =~ /^!l(?:ast)?t(?:weet)?/ );
		do_find($text, $chan, $server) 		if ($text =~ /^!findpeople/ );
	}
}
sub do_find {
	my ($text, $chan, $server) = @_;
	if ($text =~ /^!findpeople$/) {
		#sayit($server, $chan, "I will try to see if that person is on twitter if you do a !findpeople <name>");
		sayit($server, $chan, "im not ready yet D:");
	} 
	else {
		my ($unsub) = $text =~ /^!findpeople (.*)/;

		if ($unsub) {
			my $twitter = newtwitter();
			##l2handle undef here 
			eval {
				my $r = $twitter->users_search($unsub);
				my $a = Dumper($r);
				print_msg("$a");
			};
			sayit($server,$chan,"sorry, no relevant info on twitter") if ($@);
			return if $@;
		}
	}
}

sub do_last {
	my ($text, $chan, $server) = @_;
	if ($text =~ /^!l(?:ast)?t(?:weet)?$/) {
		sayit($server, $chan, "I will show you the last tweet if you do a !lasttweet <username>");
	} 
	else {
		my ($user) = $text =~ /^!l(?:ast)?t(?:weet)? @?(\w+)/;
		if ($user) {
			my $twitter = newtwitter();
			#my $a = Dumper($twitter);
			#print_msg("$a");
			eval {
				my $r = $twitter->show_user($user);
				#my $a = Dumper($r);
				#print_msg("$a");
				my ($client) = $r->{status}{source} =~ m{<a\b[^>]+>(.*?)</a>};
				$client = $r->{status}{source} if (!$client);
				my $tweet = decode_entities($r->{status}{text});
				my $lasttweet = "\@$user last tweet: " . "\"" . $tweet . "\" " . "from " . $client;
				sayit($server,$chan,$lasttweet) if ($tweet);
			};
			sayit($server, $chan, $@) if $@;
		}
	}
}
				

sub do_showuser {
	my ($text, $chan, $server) = @_;
	if ($text =~ /^\@user$/ ){
		sayit($server,$chan, "I will tell you everything about an user on twitter if you do a \@user <username>!");
	} else {
		my ($who) = $text =~ /^\@user @?(\w+)/;
		if ($who) {
			my $twitter = newtwitter();
			eval {
				my $r = $twitter->show_user($who);
				#my $a = Dumper($r);
				#print_msg("$a");

				my $user = "[\@$who] " . "Name: " . $r->{name};
				$user .= " - " . "Bio: " . $r->{description} if ($r->{description}); 
				$user .= " - " . "Location: " . $r->{location} if ($r->{location});
				my $userstats = "Tweets: " . $r->{statuses_count} . " - ". "Followers: " . $r->{followers_count} . " - " . "Following: " . $r->{friends_count};
				my $since = $r->{created_at}; #convert this plz
				#my ($client) = $r->{status}{source} =~ m{<a\b[^>]+>(.*?)</a>};
				#$client = $r->{status}{source} if (!$client);
				#my $tweet = decode_entities($r->{status}{text});
				#my $lasttweet = "Last tweet " . "\"" . $tweet . "\" " . "from " . $client;
				sayit($server,$chan,$user);
				sayit($server,$chan,$userstats);
				#sayit($server,$chan,$lasttweet) if ($tweet);
			};
			if ($@) {
				sayit($server,$chan,"$@");
				return;
			}
		} else { return }; 
	}
}
sub do_search {
	my ($text, $chan, $server) = @_;
	if ($text =~ /^!searchtwt$/) {
		sayit($server,$chan,"i will search anything on twittersphere!");
	} else {
		my ($query) = $text =~ /^!searchtwt (.*)/i;
		if ($query) {
			my $twitter = newtwitter();
			eval {
				my $r = $twitter->search($query);
				for (0..9) {
					#for (all) my $status ( @${$r->{results}}) {
					for my $status ( ${$r->{results}}[$_]) {
						#my $a = Dumper($status);
						#print_msg("$a");
						return if (!$status); 
						my $tweet = decode_entities($status->{text});
						my $msg = "\@" . $status->{from_user} . ": " . $tweet;
						sayit($server, $chan, $msg);
					}
				}
			};
			return if $@;
		}
	}
}
sub do_twittr {
	my ($text, $chan, $server) = @_;
	my ($user,$statusid) = $text =~ m{twitter\.com(?:/#!)?/([^/]+)/status(?:es)?/(\d+)}i; 
	my $apikey = Irssi::settings_get_str('twitter_apikey');
	my $secret = Irssi::settings_get_str('twitter_secret');

	my $twitter = newtwitter();
	my $status = eval { $twitter->show_status($statusid) };
	return if $@;

	#my $a = Dumper($status);
	#print_msg("$a");

	my $tweet = decode_entities($status->{text});
	my $time = $status->{created_at}; #use DateTime::Duration to do a $age ago style;
	
	my ($client) = $status->{source} =~ m{<a\b[^>]+>(.*?)</a>};
	$client = $status->{source} if (!$client);
	my $result = "\@${user} " . "tweeted ". "\"". $tweet . "\"" . " " . "from " . $client;

	my $replyurl = "http://twitter.com/" . $user . "/status/" . $status->{in_reply_to_status_id} if ($status->{in_reply_to_status_id});
	my $shorturl = makeashorterlink($replyurl) if ($replyurl);
 	$result .= ". in reply to " . $shorturl	if ($shorturl);
	sayit($server,$chan,$result) if ($result);
}

sub newtwitter {
	my $apikey = Irssi::settings_get_str('twitter_apikey');
	my $secret = Irssi::settings_get_str('twitter_secret');
	my $twitter = Net::Twitter::Lite->new(
		#edit Lite.pm to make this permanent? 
		oauth_urls => {
			request_token_url 	=> 	'https://api.twitter.com/oauth/request_token',
			access_token_url 	=> 	'https://api.twitter.com/oauth/access_token',
			authorization_url 	=> 	'https://api.twitter.com/oauth/authorize',
		},
		consumer_key		=> 	$apikey,
		consumer_secret		=> 	$secret,
		apiurl			=>	'https://api.twitter.com/1/',
		ssl			=>	1,
		source 			=> 	'squeebot',
	);
	my ($at, $ats) = restore_tokens(); #this seems like forever
	if ($at && $ats) {
		$twitter->access_token($at);
		$twitter->access_token_secret($ats);
	}
	return $twitter;
}

sub restore_tokens {
	my $at = Irssi::settings_get_str('twitter_access_token');
	my $ats = Irssi::settings_get_str('twitter_access_token_secret');
	return ($at, $ats);
}



#dont really need this, do the tokens manually
sub save_tokens {
	my ($at, $ats) = @_;
	Irssi::settings_set_str('twitter_access_token',$at);
	Irssi::settings_set_str('twitter_access_token_secret',$ats);
}

sub sayit { 
	my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}                                         
sub print_msg { active_win()->print("@_"); }
signal_add("message public","msg_pub");
Irssi::settings_add_str('twitter', 'twitter_apikey', '');
Irssi::settings_add_str('twitter', 'twitter_secret', '');
Irssi::settings_add_str('twitter', 'twitter_access_token', '');
Irssi::settings_add_str('twitter', 'twitter_access_token_secret', '');
