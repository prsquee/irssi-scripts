use Irssi qw ( print signal_add settings_get_str settings_add_str settings_set_str );
use strict;
use warnings;
use Data::Dumper;
use WWW::WolframAlpha;

signal_add('wolfram','askWolfram');
settings_add_str('wolfram', 'wa_appid', '');

my $wa = WWW::WolframAlpha->new (
  appid => settings_get_str('wa_appid'),
);

sub askWolfram {
  my($server, $chan, $query) = @_;
  my $question = $wa->query( input => $query ); 
  if ($question->success) {
    foreach my $pod (@{$question->pods}) {
      print (CRAP Dumper($pod));
    }
  }
}


