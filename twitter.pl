#twitter
#http://search.cpan.org/~mmims/Net-Twitter-Lite-0.10004/lib/Net/Twitter/Lite.pm

use Irssi qw(signal_add print settings_add_str settings_get_str settings_set_str ) ;
use strict;
use Net::Twitter::Lite; 
use HTML::Entities;
use Data::Dumper;
#use WWW::Shorten::Googl;


#init 
signal_add("fetch tweet",     "do_twitter");
signal_add("last tweet",      "do_last");
signal_add("teh fuck is who", "userbio");

#dem keis and sicrets
settings_add_str('twitter', 'twitter_apikey', '');
settings_add_str('twitter', 'twitter_secret', '');
settings_add_str('twitter', 'twitter_access_token', '');
settings_add_str('twitter', 'twitter_access_token_secret', '');
#}}}

my $twitterObj  = newtwitter();

#{{{ this is kinda useless 
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
#}}}
#{{{ fetch last tweet
sub do_last {
	my ($server,$chan,$user) = @_;
  if ($user) {
    #my $twitter = newtwitter();
    #my $a = Dumper($twitter);
    #print_msg("$a");
    eval {
      my $r = $twitterObj->show_user($user);
      my ($client) = $r->{status}{source} =~ m{<a\b[^>]+>(.*?)</a>};
      $client = $r->{status}{source} if (!$client);
      my $tweet = decode_entities($r->{status}{text});
      my $lasttweet = "\@$user last tweet: " . "\"" . $tweet . "\" " . "from " . $client;
      sayit($server,$chan,$lasttweet) if ($tweet);
    };
    print (CRAP $@) if $@;
  }
}
#}}}
#{{{ user info
sub userbio {
	my ($server,$chan,$who) = @_;
  if ($who) {
    eval {
      my $r = $twitterObj->show_user($who);
      my $user = "[\@$who] " . "Name: " . $r->{name};
      $user .= " - " . "Bio: " . $r->{description} if ($r->{description}); 
      $user .= " - " . "Location: " . $r->{location} if ($r->{location});
      my $userstats = "Tweets: " . $r->{statuses_count} . " - ". "Followers: " . $r->{followers_count} . " - " . "Following: " . $r->{friends_count};
      my $since = $r->{created_at}; #convert this pl0x
      print (CRAP $since);
      sayit($server,$chan,$user);
      sayit($server,$chan,$userstats);
    };
    print (CRAP $@) if $@;
  }
}
#}}}
#{{{ search twt
sub do_search {
	my ($text, $chan, $server) = @_;
	if ($text =~ /^!searchtwt$/) {
		sayit($server,$chan,"i will search anything on twittersphere!");
	} else {
		my ($query) = $text =~ /^!searchtwt (.*)/i;
		if ($query) {
      #my $twitter = newtwitter();
			eval {
				my $r = $twitterObj->search($query);
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
#}}}
#{{{ do twitter
sub do_twitter {
	my ($server,$chan,$text) = @_;
	my ($user,$statusid) = $text =~ m{twitter\.com(?:/#!)?/([^/]+)/status(?:es)?/(\d+)}i; 
  #my $apikey = Irssi::settings_get_str('twitter_apikey');
  #my $secret = Irssi::settings_get_str('twitter_secret');

  #my $twitter = newtwitter();
	my $status = eval { $twitterObj->show_status($statusid) };
	return if $@;

	my $tweet = decode_entities($status->{text});
	my $time = $status->{created_at}; #use DateTime::Duration to do a $age ago style;
	
	my ($client) = $status->{source} =~ m{<a\b[^>]+>(.*?)</a>};
	$client = $status->{source} if (!$client);
	my $result = "\@${user} " . "tweeted ". "\"". $tweet . "\"" . " " . "from " . $client;

	my $replyurl = "http://twitter.com/" . $user . "/status/" . $status->{in_reply_to_status_id} if ($status->{in_reply_to_status_id});
  my $shorturl = scalar('Irssi::Script::ggl')->can('do_shortme')->($replyurl) if ($replyurl);

 	$result .= ". in reply to " . $shorturl	if ($shorturl);
	sayit($server,$chan,$result) if ($result);
}
#}}}
#{{{ new twtrr 
sub newtwitter {
	my $apikey = settings_get_str('twitter_apikey');
	my $secret = settings_get_str('twitter_secret');
	my $twitter = Net::Twitter::Lite->new(
		#edit Lite.pm to make this permanent? 
    legacy_lists_api => 0,
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
  #my ($at, $ats) = restore_tokens(); #this seems like forever
	my $at  = settings_get_str('twitter_access_token');
	my $ats = settings_get_str('twitter_access_token_secret');
	if ($at && $ats) {
		$twitter->access_token($at);
		$twitter->access_token_secret($ats);
	}
	return $twitter;
}
#}}}
#{{{ signals and stuff
sub sayit {
	my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}
