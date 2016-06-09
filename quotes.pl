#quotes.pl
use Irssi qw(
  signal_add
  print
  signal_emit
  settings_add_str
  settings_get_str get_irssi_dir
);

use strict;
use warnings;
use Data::Dump; #use this to store/retrieve quotes
use File::Slurp qw( read_file write_file append_file);

#{{{ signaal and stuff
signal_add('random quotes', 'random_quotes');
signal_add('last quote', 'fetch_last');
signal_add('delete quote', 'delete_quote');
signal_add('find quote', 'find_it');
signal_add('count quotes', 'count_quotes');

settings_add_str('quotes', 'qfile', '');
#}}}


#{{{ qadd
sub quotes_add {
  my $add_this = shift;
  $add_this = strip_all($add_this);
  my $qfile_path = filename_of(@_);
  
  eval { append_file ($qfile_path, "$add_this\n") };

  print (CRAP "error adding quotes: $@") if $@;
  return ($@) ? undef : 'ok';
}
#}}}
#{{{ random one 
sub random_quotes {
  my ($server, $chan) = @_;
  my $buf = open_quotes_from($server, $chan);

  my $found = ($buf) ? '[random] ' . $$buf[rand scalar @$buf]
                     : 'no quotes from this channel'
                     ;

  sayit($server, $chan, $found);
}#}}}
#{{{ fetch last #
sub fetch_last {
  my ($server, $chan, $quote_pos) = @_;
  my $buf = open_quotes_from($server, $chan);

  if ($buf) {
    if ($quote_pos > scalar(@$buf)) {
      sayit($server, $chan, 'STAHP! too much D:');
    }
    else {
      sayit($server, $chan, "[quote] $$buf[-$quote_pos]");
    }
    return;
  } 
  else {
    sayit($server, $chan, 'no quotes from this channel.');
  }
}
#}}}
#{{{ delete a quote 
sub delete_quote {
  my ($server, $chan, $deleteme) = @_;
  my $qfile_path = filename_of($server->{tag}, $chan);

  $deleteme = strip_all($deleteme);
  $deleteme =~ s/\./\\W/g;
  use re 'eval';
  eval { $deleteme = qr/($deleteme)/; };

  if ($@) {
    sayit($server, $chan, 'nope, your regex is bad and you should feel bad.');
    return;
  }

  my $buf = eval { read_file ($qfile_path, array_ref => 1) };
  return if $@;

  my @found_quotes = grep { /($deleteme)/i } @$buf;
  if (@found_quotes) {
    if (scalar(@found_quotes) == 1) {
      #we found exactly 1 match, this what we want to delete.
      @$buf = grep { ! /$deleteme/i } @$buf;
      #write it back atomically
      write_file ($qfile_path, {atomic => 1}, @$buf);
      sayit($server, $chan, "deleted quote: \"$found_quotes[0]\"");
    } 
    else {
      sayit($server, $chan, 'stahp! that\'s more than one quote!');
      return;
    }
  } 
  else { 
    sayit($server,$chan,'quote not found!');
    return;
  }
}
#}}}
#{{{ find a quote  MAKE THIS PRETTY
sub find_it {
  my ($server, $chan, $find_me) = @_;

  my @words2find = split(/\s+/, strip_all($find_me));

  my $buf = open_quotes_from($server, $chan);
  if ($buf) {
    foreach (@words2find) {
      my $single_word = eval { qr/$_/i };
      eval { @$buf = grep { /$single_word/ } @$buf; } if ($single_word and not $@);
    }

    if (scalar(@$buf) == 0) {
      sayit($server, $chan, 'found nothing.');
    } 
    else {
      if (scalar(@$buf) >= 1 and scalar(@$buf) <= 4) {
        sayit($server, $chan, "[found] $_") for (@$buf);
      } 
      else {
        my @randfour = [];
        for (0..3) {
          my $n = rand scalar @$buf;
          $randfour[$_] = $buf->[$n];
          splice(@$buf, $n, 1);
        }
        my $totalFound = scalar(@$buf) + scalar(@randfour);
        sayit($server, $chan, "found $totalFound quotes, here are 4 random quotes");
        sayit($server,$chan,"[found] $_") foreach (@randfour);
      }
    }
  } 
  else { 
    sayit($server,$chan, "no quotes for $chan");
    return; 
  }
}
#}}}
#{{{ count quotes
sub count_quotes {
  my ($server, $chan) = @_;
  my $total = scalar @{ open_quotes_from($server, $chan) };
  sayit($server, $chan, "I have a total of $total quotes.");
}
#}}}
#{{{ misc strip all; open file; open from, print and say
sub filename_of {
  my ($server_tag, $chan) = @_;
  $chan =~ s/#/_/g;
  return get_irssi_dir() . '/scripts/datafiles/' . $server_tag . $chan . '.txt';
}
sub open_quotes_from {
  my ($server, $chan) = @_;
  my $buffer = eval { read_file(filename_of($server->{tag}, $chan), array_ref => 1) };
  return $buffer if not $@;
}
sub strip_all {
  my $text = shift;
	$text =~ s/\x03\d{0,2}(,\d{0,2})?//g; #mirc colors
	$text =~ s/\x1b\[\d+(?:,\d+)?m//g;    #ansi colors
	$text =~ s/\x02|\x16|\x1F|\x0F//g;    #bold, inverse, underline and clear
	$text =~ s/^\s+//g;                   #spaces.
	return $text;
}

sub sayit { my $s = shift; $s->command("MSG @_"); }
#}}}
