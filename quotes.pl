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
signal_add("quotes", "do_quotes");
signal_add("random quotes", "random_quotes");
settings_add_str("quotes", "qfile", '');
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

  #why cant i ternary here? sadface
  unless ($@) {
    return 'ok';
  }
  else {
    return undef;
  }
}
#}}}
#
sub random_quotes {
  my ($server, $chan) = @_;
  my $qfile_path = filename_of($server->{tag}, $chan);

    my $buf = eval { read_file ($qfile_path, array_ref => 1) };
    if ($buf) {
      sayit($server ,$chan ,'[random] ' . $$buf[rand scalar @$buf]);
    } else {
      sayit($server, $chan, 'no quotes from this channel.');
    }
}
sub do_quotes { #{{{
  my ($server, $chan, $text) = @_;
  my $qfile = get_irssi_dir()
              . "/scripts/datafiles/$server->{tag}"
              . $chan . ".txt";
  $qfile =~ s/#/_/g;

  if ($text =~ /^!qlast\s?(\d+)?$/ ) {
    my $buf = eval { read_file ($qfile, array_ref => 1) };
    if ($buf) {
      my $c = $1 || '1';
      if ($c > scalar(@$buf)) {
        sayit($server,$chan,"STAHP! too much D:");
        return;
      }
      sayit($server, $chan, "[quote] $$buf[-${c}]");
      return;
    } else {
      sayit($server,$chan, "looks like no quotes for $chan");
      return;
    }
  } #}}}
  #{{{ count total
  if ( $text =~ /^!qtotal\b/ ) {
    my $buf  = eval { read_file ($qfile, array_ref => 1) }; #total is a ref to an array of the slurped file
    if ($buf) {
      my $total = scalar @$buf;
      sayit($server,$chan,"total quotes: $total");
      return;
    } else {
      sayit($server,$chan, "I dont see any quotes for $chan");
      return;
    }
  }#}}}
  #{{{ #delete
  if ($text =~ /^!qdel(.*)/) {
    my $deleteme = strip_all($1) if ($1);
    if ($deleteme) {
      #$deleteme =~ s/\./\\W/g;
      $deleteme = qr/$deleteme/i;
      my @toBeDeleted;
      my $buf = eval { read_file ($qfile, array_ref => 1) };
      eval { @toBeDeleted = grep { /($deleteme)/ } @$buf; } if ($buf);
      if (@toBeDeleted) {
        if ( scalar(@toBeDeleted) == 1) {
          #if we found exactly 1 match
          @$buf = grep { ! /($deleteme)/ } @$buf;
          #write it atomically
          write_file ($qfile, {atomic => 1}, @$buf);
          sayit($server, $chan, "deleted quote: \"$_\"") for (@toBeDeleted);
        } else { sayit($server,$chan,"stahp! that's more than one quote!"); return; }
      } else { sayit($server,$chan,"quote not found!");                     return; }
    } else { sayit($server,$chan,"delete a quote with a few words.");       return; }
  }#}}}
  #{{{ search
  if ($text =~ /^!qs(?:earch)?(.*)/) {
    my $searchme = strip_all($1) if ($1);
    if ($searchme) {
      my @words2find = split(/\s+/, $searchme);
      my @found = eval { read_file $qfile };
      if (@found) {
        foreach (@words2find) {
          my $singleWord = eval { qr/$_/i } ;
          #$singleWord =~ s%/%%;
          eval { @found = grep { /$singleWord/ } @found; } if ($singleWord and not $@);
        }

        if (scalar(@found) == 0) {
          sayit($server,$chan,"found nothin'");
        } else {
            if (scalar(@found) >= 1 and scalar(@found) <= 4) {
              #si encontro menos de 4
              sayit($server,$chan, "[found] $_") for (@found);
            } else {
                #si encontro mas de 4, tirar 4 random quotes de los encontrados
                my @randq = [];
                for (0..3) {
                  my $n = rand scalar @found;
                  $randq[$_] = $found[$n];
                  splice(@found, $n, 1);
                }
                my $totalFound = scalar(@found) + scalar(@randq);
                sayit($server,$chan,"found $totalFound quotes, here are 4 random quotes");
                sayit($server,$chan,"[found] $_") foreach (@randq);
              }
        }
      } else { sayit($server,$chan, "no quotes for $chan");   return; }
    } else { sayit($server,$chan,"I can find you a quote.");  return;}
  }#}}}
} #do_quotes ends here
#}}}
#{{{ misc strip all; open file; print and say
sub strip_all {
  my $text = shift;
	$text =~ s/\x03\d{0,2}(,\d{0,2})?//g; #mirc colors
	$text =~ s/\x1b\[\d+(?:,\d+)?m//g;    #ansi colors
	$text =~ s/\x02|\x16|\x1F|\x0F//g;    #bold, inverse, underline and clear
	$text =~ s/^\s+//g;				            #espacios vacios al ppio
	return $text;
}

sub sayit { my $s = shift; $s->command("MSG @_"); }

#}}}
