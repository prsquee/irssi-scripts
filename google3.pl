# google search
# http://search.cpan.org/~manwar/WWW-Google-CustomSearch-0.04/lib/WWW/Google/CustomSearch.pm
#
use strict;
use warnings;
use Irssi qw( signal_add print settings_add_str settings_get_str) ;
use utf8;
use Encode qw(decode);
use Data::Dumper;
use WWW::Google::CustomSearch;

settings_add_str('gsearch', 'search_apikey', '');
settings_add_str('gsearch', 'engine_id', '' );

my $engine  = WWW::Google::CustomSearch->new(
  api_key => settings_get_str('search_apikey'),
  cx      => settings_get_str('engine_id'),
  alt     => 'json',
  num     => 4
);

sub do_google {
  my ($server,$chan,$query) = @_;
  my $res = $engine->search($query);
  #print (CRAP Dumper($res->{request}->{page}->{totalResults}));

  if ($res->{request}->{page}->{totalResults} > 0) {
    foreach my $items (@{$res->items}) {
      my $title = decode("utf8", $items->{title});
      sayit($server,$chan,"[gugl] $items->{link} - $title");
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
