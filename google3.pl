# google search
# http://search.cpan.org/~manwar/WWW-Google-CustomSearch-0.04/lib/WWW/Google/CustomSearch.pm
#
use Irssi qw( signal_add print settings_add_str settings_get_str) ;
use utf8;
use Encode;
use Data::Dumper;
use WWW::Google::CustomSearch;

#signal_add("message public","msg_pub");
settings_add_str('gsearch', 'search_apikey', '');
settings_add_str('gsearch', 'engine_id', '' );

my $engine  = WWW::Google::CustomSearch->new(
  api_key => settings_get_str('search_apikey'),
  alt => json,
  cx => settings_get_str('engine_id'),
  num => 4
);

sub do_google {
	my ($server,$chan,$query) = @_;
  #my ($query) = $text =~ /^!g(?:oogle)? (.*)$/; 
  #if ($query =~ /^google$/i) {
  #  sayit($server,$chan,"no! this will break the internet!");
  #  return;
  #}
  #my $query8 = uri_escape($query);
	my $res = $engine->search($query);
  # print (CRAP Dumper($res));
	#el obj 'queries' contiene 2 arrays, 'nextPage' y 'request'.
	#cada uno es un array de un solo value.
	#each value contiene varios objects mas.
	#so, we have:
	#${$res->{queries}->{request}}[0]{totalResults}");
	#i dont wanna do this anymore :(
	#this looks better tho:
	if ($res->{queries}->{request}->[0]{totalResults} > 0) {
		foreach my $items (@{$res->{items}}) {
			my $title = Encode::decode("utf8", $items->{title});
      #if (utf8::is_utf8($title)) {
      #  print(CRAP "UTF8 detected: $title");
      #  my $out = Encode::decode("utf8", $title);
      #  print (CRAP $out);
      #}
			my $link = $items->{link};
			sayit($server,$chan,"[gugl] $link - $title");
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
signal_add("google me","do_google");
