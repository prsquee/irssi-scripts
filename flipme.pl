use Irssi qw ( print signal_add );
use Modern::Perl '2015';
use utf8;
use strict;
use warnings;
use Data::Dumper;
use Encode qw (encode decode);

#{{{ upside down map
my %upside_down_map = ( 
  'A' => 'ᗄ',
  'B' => 'ᗺ',
  'C' => 'Ɔ',
  'D' => 'ᗡ',
  'E' => 'Ǝ',
  'F' => 'Ⅎ',
  'G' => '⅁',
  'H' => 'H',
  'I' => 'I',
  'J' => 'ᒋ',
  'K' => '丬',
  'L' => '⅂',
  'M' => 'W',
  'N' => 'N',
  'O' => 'O',
  'P' => 'Ԁ',
  'Q' => 'Ό',
  'R' => 'ᴚ',
  'S' => 'S',
  'T' => '⊥',
  'U' => 'Ո',
  'V' => 'Λ',
  'W' => 'M',
  'X' => 'X',
  'Y' => '⅄',
  'Z' => 'Z',
  'a' => 'ɐ',
  'b' => 'q',
  'c' => 'ɔ',
  'd' => 'p',
  'e' => 'ə',
  'f' => 'ɟ',
  'g' => 'ɓ',
  'h' => 'ɥ',
  'i' => 'ᴉ',
  'j' => 'ɾ',
  'k' => 'ʞ',
  'l' => 'l',
  'm' => 'ɯ',
  'n' => 'u',
  'o' => 'o',
  'p' => 'd',
  'q' => 'b',
  'r' => 'ɹ',
  's' => 's',
  't' => 'ʇ',
  'u' => 'n',
  'v' => 'ʌ',
  'w' => 'ʍ',
  'x' => 'x',
  'y' => 'ʎ',
  'z' => 'z',
  '0' => '0',
  '1' => '⇂',
  '2' => 'Ƨ',
  '3' => 'ε',
  '4' => 'ᔭ',
  '5' => '5',
  '6' => '9',
  '7' => 'L',
  '8' => '8',
  '9' => '6',
  '.' => '˙',
  ',' => '‘',
  '-' => '-',
  ':' => ':',
  ';' => '؛',
  '!' => '¡',
  '?' => '¿',
  '&' => '⅋',
  '(' => ')',
  '<' => '>',
  '[' => ']',
  '_' => '‾',
  '{' => '}',
  '‾' => '_',
  '┻' => '┬',
  '━' => '─',
);

%upside_down_map = (%upside_down_map, reverse %upside_down_map);
#}}}

my $tr = eval( 
  sprintf 'sub { tr/%s/%s/ }',
    map { quotemeta join '', @{ $_ } }
      [ keys %upside_down_map ], [ values %upside_down_map ]
);

sub flip_text {
  my $text = shift;
  $tr->() for $text;
  return scalar reverse $text;
}
