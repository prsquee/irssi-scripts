# http://search.cpan.org/~milovidov/Lingua-Translate-Bing-0.04/lib/Lingua/Translate/Bing.pm
use Irssi qw(signal_add print settings_get_str settings_add_str) ;
use strict;
use warnings;
use Lingua::Translate::Bing; 
use Data::Dumper;
use Encode qw (encode decode);
use URL::Encode qw( url_encode );

settings_add_str('apikeys', 'azure_client_secret','');
signal_add('need translate', 'do_translation');

my %langs = (
  'ar' => 'Arabic',
  'cs' => 'Czech',
  'da' => 'Danish',
  'de' => 'German',
  'en' => 'English',
  'et' => 'Estonian',
  'fi' => 'Finnish',
  'fr' => 'French',
  'nl' => 'Dutch',
  'el' => 'Greek',
  'he' => 'Hebrew',
  'ht' => 'Haitian',
  'hu' => 'Hungarian',
  'id' => 'Indonesian',
  'it' => 'Italian',
  'ja' => 'Japanese',
  'ko' => 'Korean',
  'lt' => 'Lithuanian',
  'lv' => 'Latvian',
  'no' => 'Norwegian',
  'pl' => 'Polish',
  'pt' => 'Portuguese',
  'ro' => 'Romanian',
  'es' => 'Spanish',
  'ru' => 'Russian',
  'sk' => 'Slovak',
  'sl' => 'Slovene',
  'sv' => 'Swedish',
  'th' => 'Thai',
  'tr' => 'Turkish',
  'uk' => 'Ukrainian',
  'vi' => 'Vietnamese',
  'zh' => 'Chinese',
  'zh-CHS' => 'Simplified Chinese',
  'zh-CHT' => 'Traditional Chinese',
);

my $babelfish = Lingua::Translate::Bing->new( 
                  client_id      => 'sq_irc_bot',
                  client_secret  => settings_get_str('azure_client_secret')
                );

sub do_translation {
  my ($server, $chan, $to_this, $to_translate) = @_;
  $to_translate = decode('utf8', $to_translate);
  my $from_this = $babelfish->detect($to_translate);
  #my $translated = $babelfish->translate($to_translate, $to_this, $from_this);
  my $translated = $babelfish->translate($to_translate, $to_this);

  if ($translated) {
    sayit($server, $chan, "from $langs{$from_this} to $langs{$to_this}: " . $translated);
  }
  else {
    sayit($server, $chan, "couln't translate from that.");
  }
}
sub sayit { my $s = shift; $s->command("MSG @_"); }
