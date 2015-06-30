#quotes.pl
#TODO refactor this
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
signal_add('quotes', 'do_quotes');
signal_add('random quotes', 'random_quotes');
signal_add('last quote', 'fetch_last');
signal_add('delete quote', 'delete_quote');
signal_add('find quote', 'find_it');

settings_add_str('quotes', 'qfile', '');
#}}}


sub filename_of {
  my ($server_tag, $chan) = @_;
  $chan =~ s/#/_/g;
  return get_irssi_dir() . '/scripts/datafiles/' . $server_tag . $chan . '.txt';
}

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
  my $qfile_path = filename_of($server->{tag}, $chan);
  my $buf = eval { read_file ($qfile_path, array_ref => 1) };

  my $found = ($buf) ? '[random] ' . $$buf[rand scalar @$buf]
                     : 'no quotes from this channel'
                     ;

  sayit($server, $chan, $found);
}#}}}
#{{{ fetch last #
sub fetch_last {
  my ($server, $chan, $quote_pos) = @_;
  my $qfile_path = filename_of($server->{tag}, $chan);

  my $buf = eval { read_file ($qfile_path, array_ref => 1) };
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
  my $qfile_path = filename_of($server->{tag}, $chan);
  $find_me = strip_all($find_me);

  my @words2find = split(/\s+/, $find_me);
  my $found  = eval { read_file ($qfile_path, array_ref => 1) };
  if ($found) {
    foreach (@words2find) {
      my $singleWord = eval { qr/$_/i };
      eval { @$found = grep { /$singleWord/ } @$found; } if ($singleWord and not $@);
    }

    if (scalar(@$found) == 0) {
      sayit($server, $chan, 'found nothing.');
    } 
    else {
      if (scalar(@$found) >= 1 and scalar(@$found) <= 4) {
        sayit($server, $chan, "[found] $_") for (@$found);
      } 
      else {
        my @randq = [];
        for (0..3) {
          my $n = rand scalar @$found;
          $randq[$_] = $found->[$n];
          splice(@$found, $n, 1);
        }
        my $totalFound = scalar(@$found) + scalar(@randq);
        sayit($server, $chan, "found $totalFound quotes, here are 4 random quotes");
        sayit($server,$chan,"[found] $_") foreach (@randq);
      }
    }
  } 
  else { 
    sayit($server,$chan, "no quotes for $chan");
    return; 
  }
}
#}}}
sub do_quotes { #{{{
  my ($server, $chan, $text) = @_;
  my $qfile = get_irssi_dir()
              . "/scripts/datafiles/$server->{tag}"
              . $chan . ".txt";
  $qfile =~ s/#/_/g;

  #{{{ count total
  if ( $text =~ /^!qtotal\b/ ) {
    my $buf  = eval { read_file ($qfile, array_ref => 1) }; #total is a ref to an array of the slurped file
    if ($buf) {
      my $total = scalar @$buf;
      sayit($server,$chan,"total quotes: $total");
      return;
    } else {
      sayit($server, $chan, "I dont see any quotes for $chan");
      return;
    }
  }#}}}
} #do_quotes ends here
#}}}
#{{{ misc strip all; open file; print and say
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
